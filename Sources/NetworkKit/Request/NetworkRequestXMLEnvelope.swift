import Foundation

public struct NetworkRequestXMLEnvelope {
   public struct XMLBody {
      public enum XMLBodyType: String {
         case stringType = "string"
         case longType = "long"
      }
      let key: String
      let value: Any
      let type: XMLBodyType
      var schema: String {
         switch type {
         case .stringType: "s"
         case .longType: "d"
         }
      }
      
      public init(key: String, value: Any, type: XMLBodyType) {
         self.key = key
         self.value = value
         self.type = type
      }
   }
   
   let xmlVersion: String = "1.0"
   let xmlEncoding: String = "utf-8"
   let envelopeKey: String = "v"
   let envelope: String = "http://schemas.xmlsoap.org/soap/envelope/"
   let encodingKey: String = "c"
   let encoding: String = "http://schemas.xmlsoap.org/soap/encoding/"
   let schemaKey: String = "d"
   let schema: String = "http://www.w3.org/2001/XMLSchema"
   let instanceKey: String = "i"
   let instance: String = "http://www.w3.org/2001/XMLSchema-instance"
   let namespace: String = "http://tempuri.org/"
   public let methodName: String
   let body: [XMLBody]
   
   // MARK: - Init
   public init(methodName: String, body: [XMLBody]) {
      self.methodName = methodName
      self.body = body
   }
   
   // MARK: - Properties
   public var soapAction: String { "\(namespace)IService1/\(methodName)" }
   
   public var contentLenght: Int { documentString.count }
   
   public var documentData: Data? { documentString.data(using: .utf8) }
   
   private var documentString: String {
      """
      <?xml version="\(xmlVersion)" encoding="\(xmlEncoding)"?>
      <\(envelopeKey):Envelope xmlns:\(envelopeKey)="\(envelope)" xmlns:\(encodingKey)="\(encoding)" xmlns:\(schemaKey)="\(schema)" xmlns:\(instanceKey)="\(instance)">
         <\(envelopeKey):Header />
         <\(envelopeKey):Body>
            <\(methodName) xmlns="\(namespace)" id="o0" \(encodingKey):root="1">
               \(bodyProperties)
            </\(methodName)>
         </\(envelopeKey):Body>
      </\(envelopeKey):Envelope>
      """
   }
   
   private var bodyProperties: String {
      let body = body.compactMap { xmlBody in
         "<\(xmlBody.key) \(instanceKey):type=\"\(xmlBody.schema):\(xmlBody.type.rawValue)\">\(xmlBody.value)</\(xmlBody.key)>"
      }
      return body.joined(separator: "\n         ")
   }
}
