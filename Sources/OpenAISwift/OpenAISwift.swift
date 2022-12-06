import Foundation

public enum OpenAIError: Error {
    case genericError(error: Error)
    case decodingError(error: Error)
}

public class OpenAISwift {
    fileprivate(set) var token: String?
    
    public init(authToken: String) {
        self.token = authToken
    }
}

extension OpenAISwift {
    /// Send a Completion to the OpenAI API
    /// - Parameters:
    ///   - prompt: The Text Prompt
    ///   - model: The AI Model to Use
    ///   - completionHandler: Returns an OpenAI Data Model
    public func sendCompletion(with prompt: String, model: String, completionHandler: @escaping ((OpenAI?, OpenAIError?) -> Void)) {
        let endpoint = Endpoint.completions
        let body = Command(prompt: prompt, model: model)
        let request = prepareRequest(endpoint, body: body)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(nil, OpenAIError.genericError(error: error))
            } else if let data = data {
                do {
                    let res = try JSONDecoder().decode(OpenAI.self, from: data)
                    completionHandler(res, nil)
                } catch {
                    completionHandler(nil, OpenAIError.decodingError(error: error))
                }
            }
        }
        
        task.resume()
    }
    
    private func prepareRequest<BodyType: Encodable>(_ endpoint: Endpoint, body: BodyType) -> URLRequest {
        var urlComponents = URLComponents(url: URL(string: endpoint.baseURL())!, resolvingAgainstBaseURL: true)
        urlComponents?.path = endpoint.path
        var request = URLRequest(url: urlComponents!.url!)
        request.httpMethod = endpoint.method
        
        if let token = self.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(body) {
            request.httpBody = encoded
        }
        
        return request
    }
}