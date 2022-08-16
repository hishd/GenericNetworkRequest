import Foundation
import UIKit

enum NetworkError: Error {
    case invalidResponse(String?)
    case badUrl
    case decodingError
    case unknownError(String)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let message):
            return NSLocalizedString(message ?? "Invalid Network Response", comment: "Invalid Response")
        case .badUrl:
            return NSLocalizedString("Bad Url found", comment: "Bad Url")
        case .decodingError:
            return NSLocalizedString("Error occurred while decoding the response", comment: "Decoding Error")
        case .unknownError(let message):
            return NSLocalizedString(message, comment: "Unknown Error")
        }
    }
}


enum HttpMethod {
    case get([URLQueryItem])
    case post(Data?)
    case put(Data?)
    case delete
    
    var name: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        case .delete: return "DELETE"
        }
    }
}

struct Resource {
    let url: URL
    var method: HttpMethod = .get([])
}

class WebService {
    func load<T: Codable>(_ resource: Resource) async throws -> T {
        
        var request: URLRequest?
        
        switch resource.method {
        case .post(let data):
            request = try createPostOrPutRequest(for: resource.url, method: resource.method.name, body: data)
        case .get(let quertItems):
            request = try createGetRequest(for: resource.url, queryItems: quertItems)
        case .put(let data):
            request = try createPostOrPutRequest(for: resource.url, method: resource.method.name, body: data)
        case .delete:
            request = try createDeleteRequest(for: resource.url, method: resource.method.name)
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Content-Type":"application/json"]
        let session = URLSession(configuration: configuration)
        
        guard let request = request else {
            throw NetworkError.unknownError("Could not create network request")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorResponse = String(data: data, encoding: String.Encoding.utf8) {
                throw NetworkError.invalidResponse(errorResponse)
            } else {
                throw NetworkError.invalidResponse(nil)
            }
        }
        
        guard let result = try? JSONDecoder().decode(T.self, from: data) else {
            throw NetworkError.decodingError
        }
        
        return result
    }
    
    private func createGetRequest(for url: URL, queryItems: [URLQueryItem]) throws -> URLRequest{
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw NetworkError.badUrl
        }
        return URLRequest(url: url)
    }
    
    private func createPostOrPutRequest(for url: URL, method: String, body: Data?) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        return request
    }
    
    private func createDeleteRequest(for url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        return request
    }
}

struct Product: Codable {
    let id: Int?
    let title: String
    let price: Double
    let description: String
    let category: String
    let image: String
}

struct Endpoints {
    struct ProductEndPoints {
        static func allProducts() -> URL? {
            return URL(string: "https://fakestoreapi.com/products")
        }
        static func forProductId(for id: Int) -> URL? {
            return URL(string: "https://fakestoreapi.com/products/\(id)")
        }
        static func addProduct() -> URL? {
            return URL(string: "https://fakestoreapi.com/products")
        }
        static func updateProduct(of id: Int) -> URL? {
            return URL(string: "https://fakestoreapi.com/products/\(id)")
        }
        static func deleteProduct(of id: Int) -> URL? {
            return URL(string: "https://fakestoreapi.com/products/\(id)")
        }
    }
}

func fetchProducts() async {
    guard let productsUrl = Endpoints.ProductEndPoints.allProducts() else {
        print("Invalid Url")
        return
    }
    
    let resource = Resource(url: productsUrl)
    let service = WebService()
    
    do {
        let products: [Product] =  try await service.load(resource)
        print(products)
    } catch {
        print(error.localizedDescription)
    }
}

func fetchProductById(id: Int) async {
    guard let url = Endpoints.ProductEndPoints.forProductId(for: id) else {
        print("Invalid Url")
        return
    }
    
    let resource = Resource(url: url)
    let service = WebService()
    
    do {
        let product: Product = try await service.load(resource)
        print(product)
    } catch {
        print(error.localizedDescription)
    }
}

func addSampleProduct() async {
    let sampleProduct = Product(id: nil,
                                title: "Sample Product",
                                price: 100.0,
                                description: "Sample Description",
                                category: "Sample Category",
                                image: "https://i.sample.cc")
    guard let url = Endpoints.ProductEndPoints.addProduct() else {
        print("Invalid Url")
        return
    }
    
    do {
        let data = try JSONEncoder().encode(sampleProduct)
        let resource = Resource(url: url, method: .post(data))
        let service = WebService()
        
        let addedProduct: Product = try await service.load(resource)
        print(addedProduct)
    } catch {
        print(error.localizedDescription)
    }
}

func updateSampleProduct() async {
    let sampleProduct = Product(id: nil,
                                title: "Updatable Product",
                                price: 100.0,
                                description: "Updatable Description",
                                category: "Updatable Category",
                                image: "https://i.updatable.cc")
    guard let url = Endpoints.ProductEndPoints.updateProduct(of: 8) else {
        print("Invalid Url")
        return
    }
    
    do {
        let data = try JSONEncoder().encode(sampleProduct)
        let resource = Resource(url: url, method: .put(data))
        let service = WebService()
        
        let addedProduct: Product = try await service.load(resource)
        print(addedProduct)
    } catch {
        print(error.localizedDescription)
    }
}

func deleteProduct(of id: Int) async {
    guard let url = Endpoints.ProductEndPoints.deleteProduct(of: id) else {
        print("Invalid Url")
        return
    }
    
    let resource = Resource(url: url, method: .delete)
    let service = WebService()
    
    do {
        let product: Product = try await service.load(resource)
        print(product)
    } catch {
        print(error.localizedDescription)
    }
}

Task {
//    await fetchProducts()
//    await fetchProductById(id: 2)
//    await addSampleProduct()
//    await updateSampleProduct()
//    await deleteProduct(of: 8)
}
