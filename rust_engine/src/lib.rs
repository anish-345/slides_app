use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use serde::{Deserialize, Serialize};

// --- AVIONTI CORE DATA STRUCTURES & EXPORTS ---

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum SlideLayout {
    Title,
    TitleAndContent,
    TwoColumn,
    Blank,
    SectionHeader,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum ShapeType {
    Rectangle,
    RoundedRect,
    Circle,
    Triangle,
    Star,
    ArrowRight,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum ElementType {
    Text,
    Shape,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SlideElement {
    pub id: String,
    pub element_type: ElementType,
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
    pub rotation: f32,
    pub text: Option<String>,
    pub font_size: Option<f32>,
    pub font_color: Option<String>,
    pub is_bold: bool,
    pub is_italic: bool,
    pub shape_type: Option<ShapeType>,
    pub fill_color: Option<String>,
    pub border_color: Option<String>,
    pub border_width: Option<f32>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Slide {
    pub id: String,
    pub layout: SlideLayout,
    pub background_color: String,
    pub elements: Vec<SlideElement>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Presentation {
    pub id: String,
    pub title: String,
    pub author: String,
    pub created_at: String,
    pub slides: Vec<Slide>,
}

impl Presentation {
    pub fn new(title: &str) -> Self {
        let mut pres = Presentation {
            id: format!("pres_{}", std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_millis()),
            title: title.to_string(),
            author: "Avionti User".to_string(),
            created_at: "Today".to_string(),
            slides: Vec::new(),
        };

        // Slide 1 (Title slide - Executive Avionti Orange Branding)
        let slide1 = Slide {
            id: "slide_1".to_string(),
            layout: SlideLayout::Title,
            background_color: "#FFFFFF".to_string(),
            elements: vec![
                SlideElement {
                    id: "elem_title".to_string(),
                    element_type: ElementType::Text,
                    x: 60.0,
                    y: 120.0,
                    width: 680.0,
                    height: 80.0,
                    rotation: 0.0,
                    text: Some(if title.is_empty() { "Double-tap to add title".to_string() } else { title.to_string() }),
                    font_size: Some(36.0),
                    font_color: Some("#C43E1C".to_string()), // Avionti Orange
                    is_bold: true,
                    is_italic: false,
                    shape_type: None,
                    fill_color: None,
                    border_color: None,
                    border_width: None,
                },
                SlideElement {
                    id: "elem_subtitle".to_string(),
                    element_type: ElementType::Text,
                    x: 60.0,
                    y: 220.0,
                    width: 680.0,
                    height: 50.0,
                    rotation: 0.0,
                    text: Some("Built with High-Performance Rust & Flutter Engine".to_string()),
                    font_size: Some(20.0),
                    font_color: Some("#737373".to_string()),
                    is_bold: false,
                    is_italic: false,
                    shape_type: None,
                    fill_color: None,
                    border_color: None,
                    border_width: None,
                },
            ],
        };

        // Slide 2 (Content slide)
        let slide2 = Slide {
            id: "slide_2".to_string(),
            layout: SlideLayout::TitleAndContent,
            background_color: "#FFFFFF".to_string(),
            elements: vec![
                SlideElement {
                    id: "elem_heading".to_string(),
                    element_type: ElementType::Text,
                    x: 40.0,
                    y: 40.0,
                    width: 720.0,
                    height: 60.0,
                    rotation: 0.0,
                    text: Some("Executive Overview & Architecture".to_string()),
                    font_size: Some(28.0),
                    font_color: Some("#C43E1C".to_string()),
                    is_bold: true,
                    is_italic: false,
                    shape_type: None,
                    fill_color: None,
                    border_color: None,
                    border_width: None,
                },
                SlideElement {
                    id: "elem_body".to_string(),
                    element_type: ElementType::Text,
                    x: 40.0,
                    y: 120.0,
                    width: 440.0,
                    height: 200.0,
                    rotation: 0.0,
                    text: Some("• High performance native Rust slide engine\n• Native touch, mouse & keyboard gestures\n• Seamless PowerPoint UI/UX for Mobile & Desktop\n• Cross-platform vector rendering & snapping".to_string()),
                    font_size: Some(18.0),
                    font_color: Some("#333333".to_string()),
                    is_bold: false,
                    is_italic: false,
                    shape_type: None,
                    fill_color: None,
                    border_color: None,
                    border_width: None,
                },
                SlideElement {
                    id: "elem_shape_box".to_string(),
                    element_type: ElementType::Shape,
                    x: 520.0,
                    y: 130.0,
                    width: 220.0,
                    height: 160.0,
                    rotation: 0.0,
                    text: None,
                    font_size: None,
                    font_color: None,
                    is_bold: false,
                    is_italic: false,
                    shape_type: Some(ShapeType::RoundedRect),
                    fill_color: Some("#C43E1C".to_string()),
                    border_color: Some("#9C27B0".to_string()),
                    border_width: Some(2.0),
                },
            ],
        };

        pres.slides.push(slide1);
        pres.slides.push(slide2);
        pres
    }
}

// Helpers
fn c_str_to_str<'a>(ptr: *const c_char) -> &'a str {
    if ptr.is_null() {
        return "";
    }
    unsafe {
        CStr::from_ptr(ptr).to_str().unwrap_or("")
    }
}

fn to_c_string(s: String) -> *mut c_char {
    CString::new(s).unwrap_or_default().into_raw()
}

#[no_mangle]
pub extern "C" fn avionti_get_version() -> *mut c_char {
    to_c_string("Avionti Rust Core v1.0.0 (Native Studio)".to_string())
}

#[no_mangle]
pub extern "C" fn avionti_create_default_deck(title_ptr: *const c_char) -> *mut c_char {
    let title = c_str_to_str(title_ptr);
    let pres = Presentation::new(if title.is_empty() { "Avionti Presentation" } else { title });
    let json = serde_json::to_string(&pres).unwrap_or_else(|_| "{}".to_string());
    to_c_string(json)
}

#[no_mangle]
pub extern "C" fn avionti_add_slide_to_deck(deck_json_ptr: *const c_char, layout_ptr: *const c_char) -> *mut c_char {
    let json_str = c_str_to_str(deck_json_ptr);
    let layout_str = c_str_to_str(layout_ptr);
    
    let mut pres: Presentation = match serde_json::from_str(json_str) {
        Ok(p) => p,
        Err(_) => return to_c_string(json_str.to_string()),
    };

    let layout = match layout_str {
        "Title" => SlideLayout::Title,
        "TwoColumn" => SlideLayout::TwoColumn,
        "Blank" => SlideLayout::Blank,
        "SectionHeader" => SlideLayout::SectionHeader,
        _ => SlideLayout::TitleAndContent,
    };

    let new_slide_idx = pres.slides.len() + 1;
    let new_slide = Slide {
        id: format!("slide_{}", new_slide_idx),
        layout,
        background_color: "#FFFFFF".to_string(),
        elements: vec![
            SlideElement {
                id: format!("elem_title_{}", new_slide_idx),
                element_type: ElementType::Text,
                x: 40.0,
                y: 40.0,
                width: 720.0,
                height: 60.0,
                rotation: 0.0,
                text: Some(format!("Slide {} Heading", new_slide_idx)),
                font_size: Some(28.0),
                font_color: Some("#262626".to_string()),
                is_bold: true,
                is_italic: false,
                shape_type: None,
                fill_color: None,
                border_color: None,
                border_width: None,
            },
            SlideElement {
                id: format!("elem_body_{}", new_slide_idx),
                element_type: ElementType::Text,
                x: 40.0,
                y: 120.0,
                width: 720.0,
                height: 180.0,
                rotation: 0.0,
                text: Some("Double-tap to add content or insert shapes from the toolbar.".to_string()),
                font_size: Some(18.0),
                font_color: Some("#555555".to_string()),
                is_bold: false,
                is_italic: false,
                shape_type: None,
                fill_color: None,
                border_color: None,
                border_width: None,
            },
        ],
    };

    pres.slides.push(new_slide);
    to_c_string(serde_json::to_string(&pres).unwrap_or_else(|_| json_str.to_string()))
}

#[no_mangle]
pub extern "C" fn avionti_add_shape_to_slide(
    deck_json_ptr: *const c_char,
    slide_idx: i32,
    shape_type_ptr: *const c_char,
    fill_color_ptr: *const c_char,
    x: f32,
    y: f32,
    w: f32,
    h: f32,
) -> *mut c_char {
    let json_str = c_str_to_str(deck_json_ptr);
    let shape_str = c_str_to_str(shape_type_ptr);
    let fill_color = c_str_to_str(fill_color_ptr);

    let mut pres: Presentation = match serde_json::from_str(json_str) {
        Ok(p) => p,
        Err(_) => return to_c_string(json_str.to_string()),
    };

    let idx = slide_idx as usize;
    if idx < pres.slides.len() {
        let shape_type = match shape_str {
            "Circle" => ShapeType::Circle,
            "Triangle" => ShapeType::Triangle,
            "Star" => ShapeType::Star,
            "ArrowRight" => ShapeType::ArrowRight,
            "RoundedRect" => ShapeType::RoundedRect,
            _ => ShapeType::Rectangle,
        };

        let new_elem = SlideElement {
            id: format!("shape_{}", std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_millis()),
            element_type: ElementType::Shape,
            x,
            y,
            width: w,
            height: h,
            rotation: 0.0,
            text: None,
            font_size: None,
            font_color: None,
            is_bold: false,
            is_italic: false,
            shape_type: Some(shape_type),
            fill_color: Some(if fill_color.is_empty() { "#C43E1C".to_string() } else { fill_color.to_string() }),
            border_color: Some("#333333".to_string()),
            border_width: Some(1.5),
        };

        pres.slides[idx].elements.push(new_elem);
    }

    to_c_string(serde_json::to_string(&pres).unwrap_or_else(|_| json_str.to_string()))
}

#[no_mangle]
pub extern "C" fn avionti_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

// --- SLIDES STUDIO NATIVE CORE EXPORTS ---

#[no_mangle]
pub extern "C" fn rust_engine_version() -> *const c_char {
    let s = CString::new("RustEngine 1.0.0 (Unified High-Performance Slide Core)").unwrap();
    s.into_raw()
}

#[no_mangle]
pub extern "C" fn rust_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

/// Snapping calculation in Rust:
/// Checks if an element at (pos, size) aligns with target guides (e.g. Center, Edge)
/// Returns snapped position if within snap_threshold, otherwise returns pos
#[no_mangle]
pub extern "C" fn rust_snap_axis(pos: f64, size: f64, target: f64, threshold: f64) -> f64 {
    // 1. Check start edge
    if (pos - target).abs() <= threshold {
        return target;
    }
    // 2. Check center
    let center = pos + (size / 2.0);
    if (center - target).abs() <= threshold {
        return target - (size / 2.0);
    }
    // 3. Check end edge
    let end = pos + size;
    if (end - target).abs() <= threshold {
        return target - size;
    }
    pos
}

/// Fast word and character counter for text editing buffer
#[repr(C)]
pub struct TextStats {
    pub word_count: u32,
    pub char_count: u32,
    pub line_count: u32,
}

#[no_mangle]
pub extern "C" fn rust_analyze_text(ptr: *const c_char) -> TextStats {
    if ptr.is_null() {
        return TextStats { word_count: 0, char_count: 0, line_count: 0 };
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let text = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return TextStats { word_count: 0, char_count: 0, line_count: 0 },
    };

    let word_count = text.split_whitespace().count() as u32;
    let char_count = text.chars().count() as u32;
    let line_count = text.lines().count() as u32;

    TextStats {
        word_count,
        char_count,
        line_count: if line_count == 0 && !text.is_empty() { 1 } else { line_count },
    }
}

#[derive(Serialize, Deserialize)]
struct SlideQuery {
    slides: Vec<SlideData>,
    query: String,
}

#[derive(Serialize, Deserialize)]
struct SlideData {
    id: String,
    elements: Vec<ElementData>,
}

#[derive(Serialize, Deserialize)]
struct ElementData {
    id: String,
    text: Option<String>,
}

#[derive(Serialize, Deserialize)]
struct SearchResult {
    slide_id: String,
    element_id: String,
    matched_text: String,
}

/// High-speed slide text search across entire deck
#[no_mangle]
pub extern "C" fn rust_search_deck(payload_ptr: *const c_char) -> *mut c_char {
    if payload_ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(payload_ptr) };
    let json_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let data: SlideQuery = match serde_json::from_str(json_str) {
        Ok(d) => d,
        Err(_) => return std::ptr::null_mut(),
    };

    let q = data.query.to_lowercase();
    let mut results: Vec<SearchResult> = Vec::new();

    for slide in data.slides {
        for elem in slide.elements {
            if let Some(txt) = elem.text {
                if txt.to_lowercase().contains(&q) {
                    results.push(SearchResult {
                        slide_id: slide.id.clone(),
                        element_id: elem.id.clone(),
                        matched_text: txt,
                    });
                }
            }
        }
    }

    let out = serde_json::to_string(&results).unwrap_or_default();
    CString::new(out).map(|s| s.into_raw()).unwrap_or(std::ptr::null_mut())
}
