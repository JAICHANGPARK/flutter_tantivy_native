use once_cell::sync::OnceCell;
use serde_json;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::path::PathBuf;
use std::ptr;
use std::sync::Mutex;
use tantivy::collector::TopDocs;
use tantivy::query::QueryParser;
use tantivy::schema::*;
use tantivy::{doc, Index, IndexReader, IndexWriter, TantivyDocument};

static LAST_ERROR: OnceCell<Mutex<Option<String>>> = OnceCell::new();
fn set_error(err: impl ToString) {
    let cell = LAST_ERROR.get_or_init(|| Mutex::new(None));
    *cell.lock().unwrap() = Some(err.to_string());
}

fn take_error() -> Option<String> {
    let cell = LAST_ERROR.get_or_init(|| Mutex::new(None));
    cell.lock().unwrap().take()
}

// Global state for the Tantivy index
struct TantivyState {
    index: Index,
    reader: IndexReader,
    writer: Mutex<IndexWriter>,
    default_fields: Vec<Field>,
}

static STATE: OnceCell<TantivyState> = OnceCell::new();

// Helper to convert Rust String to C string pointer the caller must free.
fn to_c_string(s: String) -> *mut c_char {
    CString::new(s)
        .unwrap_or_else(|_| CString::new("" /* fallback */).unwrap())
        .into_raw()
}

#[no_mangle]
pub extern "C" fn tantivy_last_error() -> *mut c_char {
    match take_error() {
        Some(msg) => to_c_string(msg),
        None => ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn tantivy_free_str(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(s));
    }
}

#[no_mangle]
pub extern "C" fn tantivy_init(dir_path: *const c_char) -> c_int {
    if dir_path.is_null() {
        set_error("dir_path is null");
        return -1;
    }

    let c_str = unsafe { CStr::from_ptr(dir_path) };
    let dir = match c_str.to_str() {
        Ok(s) => s,
        Err(e) => {
            set_error(format!("Invalid UTF-8 path: {e}"));
            return -2;
        }
    };

    let index_dir = PathBuf::from(dir);

    // 기존 인덱스가 있으면 열고, 없으면 새로 생성
    let (index, text_field) = if index_dir.join("meta.json").exists() {
        // 기존 인덱스 열기
        let index = match Index::open_in_dir(&index_dir) {
            Ok(idx) => idx,
            Err(e) => {
                set_error(format!("Failed to open existing index: {e}"));
                return -3;
            }
        };
        let schema = index.schema();
        let text = match schema.get_field("text") {
            Ok(f) => f,
            Err(e) => {
                set_error(format!("text field not found in existing index: {e}"));
                return -4;
            }
        };
        (index, text)
    } else {
        // 새 인덱스 생성
        let mut schema_builder = Schema::builder();
        let text = schema_builder.add_text_field("text", TEXT | STORED);
        let schema = schema_builder.build();

        let index = match Index::create_in_dir(&index_dir, schema.clone()) {
            Ok(idx) => idx,
            Err(e) => {
                set_error(format!("Failed to create new index: {e}"));
                return -3;
            }
        };
        (index, text)
    };

    let default_fields = vec![text_field];
    let writer = match index.writer(50_000_000) {
        Ok(w) => w,
        Err(e) => {
            set_error(format!("Failed to create writer: {e}"));
            return -4;
        }
    };

    let reader = match index.reader() {
        Ok(r) => r,
        Err(e) => {
            set_error(format!("Failed to create reader: {e}"));
            return -5;
        }
    };

    let _ = STATE.set(TantivyState {
        index,
        reader,
        writer: Mutex::new(writer),
        default_fields,
    });

    0
}

#[no_mangle]
pub extern "C" fn tantivy_add_doc(text_ptr: *const c_char) -> c_int {
    let state = match STATE.get() {
        Some(s) => s,
        None => {
            set_error("tantivy not initialized");
            return -1;
        }
    };

    if text_ptr.is_null() {
        set_error("text is null");
        return -2;
    }

    let c_str = unsafe { CStr::from_ptr(text_ptr) };
    let text = match c_str.to_str() {
        Ok(s) => s,
        Err(e) => {
            set_error(format!("Invalid UTF-8 text: {e}"));
            return -3;
        }
    };

    let schema = state.index.schema();
    let text_field = match schema.get_field("text") {
        Ok(f) => f,
        Err(e) => {
            set_error(format!("text field missing in schema: {e}"));
            return -4;
        }
    };

    let doc = doc!(text_field => text);

    let mut writer = state.writer.lock().unwrap();
    if let Err(e) = writer.add_document(doc) {
        set_error(format!("Failed to add document: {e}"));
        return -5;
    }

    if let Err(e) = writer.commit() {
        set_error(format!("Failed to commit: {e}"));
        return -6;
    }

    0
}
#[no_mangle]
pub extern "C" fn tantivy_search(query_ptr: *const c_char, top_k: c_int) -> *mut c_char {
    let state = match STATE.get() {
        Some(s) => s,
        None => {
            set_error("tantivy not initialized");
            return ptr::null_mut();
        }
    };

    if query_ptr.is_null() {
        set_error("query is null");
        return ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(query_ptr) };
    let query = match c_str.to_str() {
        Ok(s) => s,
        Err(e) => {
            set_error(format!("Invalid UTF-8 query: {e}"));
            return ptr::null_mut();
        }
    };

    let searcher = state.reader.searcher();
    let query_parser = QueryParser::for_index(&state.index, state.default_fields.clone());
    let q = match query_parser.parse_query(query) {
        Ok(q) => q,
        Err(e) => {
            set_error(format!("Failed to parse query: {e}"));
            return ptr::null_mut();
        }
    };

    let top_k = if top_k <= 0 { 10 } else { top_k as usize };
    let top_docs = match searcher.search(&q, &TopDocs::with_limit(top_k)) {
        Ok(res) => res,
        Err(e) => {
            set_error(format!("Search failed: {e}"));
            return ptr::null_mut();
        }
    };

    let schema = state.index.schema();
    let text_field = match schema.get_field("text") {
        Ok(f) => f,
        Err(e) => {
            set_error(format!("text field missing: {e}"));
            return ptr::null_mut();
        }
    };

    let mut results = Vec::new();
    for (score, doc_address) in top_docs {
        if let Ok(retrieved) = searcher.doc::<TantivyDocument>(doc_address) {
            let mut texts = Vec::new();
            for (field, value) in retrieved.field_values() {
                if field == text_field {
                    // CompactDocValue를 문자열로 변환
                    if let Some(s) = value.as_str() {
                        texts.push(s.to_string());
                    }
                }
            }
            results.push(serde_json::json!({
                "score": score,
                "text": texts.join(" "),
            }));
        }
    }

    let json = serde_json::Value::Array(results).to_string();
    to_c_string(json)
}
