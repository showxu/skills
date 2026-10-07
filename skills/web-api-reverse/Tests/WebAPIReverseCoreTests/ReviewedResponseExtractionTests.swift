import Testing

@testable import WebAPIReverseCore

@Suite("Reviewed response extraction")
struct ReviewedResponseExtractionTests {
  @Test("Projects an explicitly reviewed JSONP payload as JSON")
  func projectsJSONP() throws {
    let result = try ReviewedResponseExtractor.project(
      response: ResponseShape(
        status: 200,
        contentType: "application/json;charset=utf-8",
        bodySchema: .object(["type": .string("string")]),
        outcome: .success,
        businessErrorSignals: []
      ),
      fixture: .string(#"result({"code":"0","flag":true});"#),
      policy: .object([
        "callback": .string("result"),
        "kind": .string("jsonP"),
      ])
    )

    #expect(result.response.contentType == "application/json")
    guard
      case .object(let schema)? = result.response.bodySchema,
      case .object(let properties)? = schema["properties"],
      case .object(let flag)? = properties["flag"],
      case .object(let fixture)? = result.fixture
    else {
      Issue.record("Expected an extracted JSON object and inferred schema")
      return
    }
    #expect(flag["type"] == .string("boolean"))
    #expect(fixture["code"] == .string("0"))
  }

  @Test("Projects JSONP whose callback name is supplied by a request query")
  func projectsDynamicJSONPCallback() throws {
    let result = try ReviewedResponseExtractor.project(
      response: ResponseShape(
        status: 200,
        contentType: "text/javascript",
        bodySchema: .object(["type": .string("string")]),
        outcome: .success,
        businessErrorSignals: []
      ),
      fixture: .string(#"mtopjsonpmytbpc8({"code":"0"})"#),
      policy: .object([
        "callbackQueryName": .string("callback"),
        "kind": .string("jsonP"),
      ])
    )

    #expect(result.response.contentType == "application/json")
    guard case .object(let fixture)? = result.fixture else {
      Issue.record("Expected an extracted dynamic JSONP fixture")
      return
    }
    #expect(fixture["code"] == .string("0"))
  }

  @Test("JSONP requires a fixed callback or an owned callback query")
  func rejectsCallbackFreeJSONPPolicy() {
    #expect(throws: ReviewedResponseExtractionError.invalidPolicy) {
      try ReviewedResponseExtractor.validatePolicy(
        .object(["kind": .string("jsonP")])
      )
    }
  }

  @Test("Rejects a callback that differs from reviewed policy")
  func rejectsCallbackMismatch() {
    #expect(
      throws: ReviewedResponseExtractionError.callbackMismatch("result")
    ) {
      try ReviewedResponseExtractor.project(
        response: ResponseShape(
          status: 200,
          contentType: "application/json",
          bodySchema: .object(["type": .string("string")]),
          outcome: .success,
          businessErrorSignals: []
        ),
        fixture: .string(#"other({"code":"0"});"#),
        policy: .object([
          "callback": .string("result"),
          "kind": .string("jsonP"),
        ])
      )
    }
  }

  @Test("Projects one reviewed HTML script JSON payload")
  func projectsHTMLScriptJSON() throws {
    let result = try ReviewedResponseExtractor.project(
      response: ResponseShape(
        status: 200,
        contentType: "text/html; charset=utf-8",
        bodySchema: .object(["type": .string("string")]),
        outcome: .success,
        businessErrorSignals: []
      ),
      fixture: .string(
        """
        <html><head>
        <script type="application/ld+json">{"@type":"BreadcrumbList"}</script>
        <script TYPE='application/ld+json'>
          {"@type":"ProductGroup","name":"Shirt","hasVariant":[{"sku":"1"}]}
        </script>
        </head></html>
        """
      ),
      policy: .object([
        "kind": .string("htmlScriptJSON"),
        "match": .object([
          "equals": .string("ProductGroup"),
          "field": .string("@type"),
        ]),
        "scriptType": .string("application/ld+json"),
      ])
    )

    #expect(result.response.contentType == "application/json")
    guard
      case .object(let fixture)? = result.fixture,
      case .array(let variants)? = fixture["hasVariant"]
    else {
      Issue.record("Expected an extracted ProductGroup fixture")
      return
    }
    #expect(fixture["name"] == .string("Shirt"))
    #expect(variants.count == 1)
  }

  @Test("Reviewed HTML script JSON must match exactly one payload")
  func requiresUniqueHTMLScriptJSON() {
    let response = ResponseShape(
      status: 200,
      contentType: "text/html",
      bodySchema: .object(["type": .string("string")]),
      outcome: .success,
      businessErrorSignals: []
    )
    let policy: JSONValue = .object([
      "kind": .string("htmlScriptJSON"),
      "match": .object([
        "equals": .string("ProductGroup"),
        "field": .string("@type"),
      ]),
      "scriptType": .string("application/ld+json"),
    ])

    #expect(throws: ReviewedResponseExtractionError.htmlScriptJSONNotFound) {
      try ReviewedResponseExtractor.project(
        response: response,
        fixture: .string(
          #"<script type="application/ld+json">{"@type":"Article"}</script>"#
        ),
        policy: policy
      )
    }
    #expect(throws: ReviewedResponseExtractionError.htmlScriptJSONAmbiguous) {
      try ReviewedResponseExtractor.project(
        response: response,
        fixture: .string(
          """
          <script type="application/ld+json">{"@type":"ProductGroup"}</script>
          <script type="application/ld+json">{"@type":"ProductGroup"}</script>
          """
        ),
        policy: policy
      )
    }
  }

  @Test("Projects one reviewed JavaScript JSON assignment")
  func projectsJavaScriptAssignmentJSON() throws {
    let result = try ReviewedResponseExtractor.project(
      response: htmlResponse,
      fixture: .string(
        #"""
        <script>
          const text = "proData={\"id_goods\":0}";
          // proData={"id_goods":1};
          /* proData={"id_goods":2}; */
          var proData={"id_goods":521399,"sku_info":[{"stock":4}]};
        </script>
        """#
      ),
      policy: .object([
        "kind": .string("javascriptAssignmentJSON"),
        "variable": .string("proData"),
      ])
    )

    #expect(result.response.contentType == "application/json")
    guard case .object(let fixture)? = result.fixture else {
      Issue.record("Expected an extracted JavaScript assignment object")
      return
    }
    #expect(fixture["id_goods"] == .number(521_399))
  }

  @Test("Reviewed JavaScript assignment must match exactly once")
  func requiresUniqueJavaScriptAssignmentJSON() {
    let policy: JSONValue = .object([
      "kind": .string("javascriptAssignmentJSON"),
      "variable": .string("proData"),
    ])
    #expect(
      throws: ReviewedResponseExtractionError
        .javascriptAssignmentJSONNotFound
    ) {
      try ReviewedResponseExtractor.project(
        response: htmlResponse,
        fixture: .string("<script>const proDatabase={};</script>"),
        policy: policy
      )
    }
    #expect(
      throws: ReviewedResponseExtractionError
        .javascriptAssignmentJSONAmbiguous
    ) {
      try ReviewedResponseExtractor.project(
        response: htmlResponse,
        fixture: .string(
          "<script>var proData={}; let proData={\"id\":2};</script>"
        ),
        policy: policy
      )
    }
  }

  private var htmlResponse: ResponseShape {
    ResponseShape(
      status: 200,
      contentType: "text/html; charset=utf-8",
      bodySchema: .object(["type": .string("string")]),
      outcome: .success,
      businessErrorSignals: []
    )
  }
}
