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
    fn review_request(&self, text: &str) -> serde_json::Value {
        json!({
            "system_instruction": {
                "parts": {
                    "text": "You are an anime review critic, you are given the task to go through all the anime reviews and provide a review under 500 words. Split it into 3-4 Pros and Cons and a final Verdict. No need for any intro. Each pros/cons should be descriptive along with a concise title for it. Output should be in the format { pros: [ { title, description }, cons: [ { title, description }  ], verdict }"
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

    pub async fn talk(&self, prompt: &str) -> Result<ReviewResponse, reqwest::Error> {
        let gemini_api_key = self.config.secrets.gemini_api_key.as_str();
        let gemini_api_url = format!("{}{}", GEMINI_API_URL, gemini_api_key);
        println!("Calling Gemini API with url");

        let value = self.review_request(&prompt);

        println!("Final prompt: {:?}", value);

        let text = reqwest::Client::new()
            .post(gemini_api_url)
            .json(&value)
            .header("Content-Type", "application/json")
            .send()
            .await?
            .text()
            .await?;
        println!("Response from Gemini API: {:?}", text);
        let response: GeminiReponse = serde_json::from_str(&text).unwrap();
        println!("Response from Gemini API: {:?}", response);

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

        let review_response: ReviewResponse = serde_json::from_str(&text).unwrap();
        Ok(review_response)
    }
}
