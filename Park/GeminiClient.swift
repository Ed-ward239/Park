//
//  GeminiClient.swift
//  Park

import Foundation

struct GeminiClient {
    enum GeminiError: LocalizedError {
        case missingAPIKey
        case badResponse(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "No Gemini API key found. Add GEMINI_API_KEY to Secrets.plist."
            case .badResponse(let detail):
                "Couldn't interpret the sign: \(detail)"
            }
        }
    }

    private static var apiKey: String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any]
        else { return nil }
        return dict["GEMINI_API_KEY"] as? String
    }

    /// JSON schema forcing Gemini to return exactly the ParkingVerdict shape.
    private static let responseSchema: [String: Any] = [
        "type": "OBJECT",
        "properties": [
            "status": ["type": "STRING", "enum": ["safe", "caution", "danger"]],
            "summary": ["type": "STRING"],
            "breakdown": ["type": "ARRAY", "items": ["type": "STRING"]],
        ],
        "required": ["status", "summary", "breakdown"],
    ]

    func interpretSign(text: String, context: ScanContext) async throws -> ParkingVerdict {
        guard let key = Self.apiKey, !key.isEmpty else { throw GeminiError.missingAPIKey }

        let prompt = """
        You are a parking sign interpreter. Below is the OCR text of one or more stacked street \
        parking signs on a single pole, plus the driver's current context. Decide whether the \
        driver can park RIGHT NOW.

        Rules:
        - status "safe": parking is currently allowed with no upcoming restriction within 1 hour.
        - status "caution": parking is allowed but a restriction applies soon, a time limit applies, \
        payment is required, or a permit exemption might apply.
        - status "danger": parking is currently prohibited.
        - summary: ONE short plain-English sentence a driver can read in 2 seconds, including when \
        the situation changes, e.g. "You can park here until 6 pm today. Free."
        - breakdown: one line per rule on the sign, translated to plain English, most relevant first.
        - If the sign text is ambiguous or not a parking sign, use "caution" and say so in the summary.

        CURRENT CONTEXT
        Local date/time: \(context.formattedDateTime)
        Day of week: \(context.dayOfWeek)
        Public holiday today: \(context.isHoliday ? "YES — \(context.holidayName ?? "holiday")" : "no")
        City: \(context.city ?? "unknown")
        \(context.permitZoneNotes.map { "City permit notes: \($0)" } ?? "")

        SIGN TEXT (OCR)
        \(text)
        """

        var request = URLRequest(url: URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": Self.responseSchema,
                "temperature": 0.1,
                // Skip 2.5-flash's thinking phase — a kerbside verdict needs speed
                "thinkingConfig": ["thinkingBudget": 0],
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let detail = String(data: data, encoding: .utf8) ?? "unknown error"
            throw GeminiError.badResponse(detail)
        }

        // Unwrap candidates[0].content.parts[0].text, which contains the JSON verdict.
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = root["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let jsonText = parts.first?["text"] as? String,
              let verdictData = jsonText.data(using: .utf8)
        else { throw GeminiError.badResponse("unexpected response shape") }

        return try JSONDecoder().decode(ParkingVerdict.self, from: verdictData)
    }
}
