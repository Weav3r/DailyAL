use serde_json::json;

use crate::{
    config::Config,
    model::{GeminiReponse, ReviewResponse},
};

const GEMINI_API_URL: &str =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=";

#[derive(Debug, Clone)]
pub struct GeminiAPI {
    pub config: Config,
}

impl GeminiAPI {
    fn review_request(&self, system: &str, text: &str) -> serde_json::Value {
        json!({
            "system_instruction": {
                "parts": {
                    "text": system
                }
            },
            "contents": [
                {
                    "parts": [
                        {
                            "text": text
                        }
                    ]
                }
            ],
            "safetySettings": [
                {
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_NONE"
                }
            ],
            "generationConfig": {
                "response_mime_type": "application/json"
            }
        })
    }

    pub async fn talk(&self, system: &str, prompt: &str) -> Result<String, reqwest::Error> {
        let gemini_api_key = self.config.secrets.gemini_api_key.as_str();
        let gemini_api_url = format!("{}{}", GEMINI_API_URL, gemini_api_key);
        println!("Calling Gemini API with url");

        let value = self.review_request(&system, &prompt);

        let text = reqwest::Client::new()
            .post(gemini_api_url)
            .json(&value)
            .header("Content-Type", "application/json")
            .send()
            .await?
            .text()
            .await?;

        println!("Response from Gemini API");

        let response: GeminiReponse = serde_json::from_str(&text).unwrap();

        let text = response
            .candidates
            .first()
            .unwrap()
            .content
            .parts
            .first()
            .unwrap()
            .text
            .clone();

        Ok(text)
    }
}
