# Xcode Intelligence Chat Prompts Snapshot

This generated index follows the same catalog shape as the public Xcode prompt mirror,
but the files are extracted from the local Xcode bundle recorded below.

## Source

- Generated at: `2026-05-25T09:48:14.330508+00:00`
- Xcode app: `/Applications/Xcode.app`
- Developer dir: `/Applications/Xcode.app/Contents/Developer`
- Resources dir: `/Applications/Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources`
- Xcode version: `26.4.1`
- Xcode build: `24909.0.3`

## Counts

- Prompt templates: `46`
- Additional documentation: `20`
- Support files: `8`

## Resource Catalog

### System Prompt Templates (`.idechatprompttemplate`)

Grouped prompt-template files from the local Xcode bundle.

#### Basic Coding Assistant Prompts

Foundation prompts for code analysis, explanation, reasoning, and variant assistant behavior.

- [`BasicSystemPrompt.idechatprompttemplate`](prompts/BasicSystemPrompt.idechatprompttemplate) - Base coding-assistant system prompt.
- [`ReasoningSystemPrompt.idechatprompttemplate`](prompts/ReasoningSystemPrompt.idechatprompttemplate) - Reasoning-oriented coding-assistant prompt.
- [`VariantASystemPrompt.idechatprompttemplate`](prompts/VariantASystemPrompt.idechatprompttemplate) - Alternative assistant prompt variant.
- [`VariantBSystemPrompt.idechatprompttemplate`](prompts/VariantBSystemPrompt.idechatprompttemplate) - Alternative assistant prompt variant.

#### Specialized Workflow Prompts

Planner, editor, and integration prompts for code-change workflows.

- [`IntegratorSystemPrompt.idechatprompttemplate`](prompts/IntegratorSystemPrompt.idechatprompttemplate) - Code integration system prompt.
- [`IntegratorUserPrompt.idechatprompttemplate`](prompts/IntegratorUserPrompt.idechatprompttemplate) - Code integration user prompt wrapper.
- [`NewCodeIntegratorSystemPrompt.idechatprompttemplate`](prompts/NewCodeIntegratorSystemPrompt.idechatprompttemplate) - New-code integration system prompt.
- [`NewCodeIntegratorUserPrompt.idechatprompttemplate`](prompts/NewCodeIntegratorUserPrompt.idechatprompttemplate) - New-code integration user prompt wrapper.
- [`FastApplyIntegratorSystemPrompt.idechatprompttemplate`](prompts/FastApplyIntegratorSystemPrompt.idechatprompttemplate) - Fast-apply integration system prompt.
- [`FastApplyIntegratorUserPrompt.idechatprompttemplate`](prompts/FastApplyIntegratorUserPrompt.idechatprompttemplate) - Fast-apply integration user prompt wrapper.
- [`TextEditorToolSystemPrompt.idechatprompttemplate`](prompts/TextEditorToolSystemPrompt.idechatprompttemplate) - Tool-assisted text editor prompt.
- [`PlannerExecutorStylePlannerSystemPrompt.idechatprompttemplate`](prompts/PlannerExecutorStylePlannerSystemPrompt.idechatprompttemplate) - Planner-executor planner prompt.
- [`PlannerExecutorStylePlannerSystemPrompt-gpt_5.idechatprompttemplate`](prompts/PlannerExecutorStylePlannerSystemPrompt-gpt_5.idechatprompttemplate) - Planner-executor planner prompt variant.
- [`PlannerExecutorStyleNoClassify.idechatprompttemplate`](prompts/PlannerExecutorStyleNoClassify.idechatprompttemplate) - Planner-executor prompt without classification.

#### Context Provider Prompts

Templates that inject current file, selection, interface, issue, and surrounding IDE context.

- [`ContextItems.idechatprompttemplate`](prompts/ContextItems.idechatprompttemplate) - Context-item wrapper.
- [`CurrentFile.idechatprompttemplate`](prompts/CurrentFile.idechatprompttemplate) - Current file context.
- [`CurrentFileAbbreviated.idechatprompttemplate`](prompts/CurrentFileAbbreviated.idechatprompttemplate) - Abbreviated current file context.
- [`CurrentFileName.idechatprompttemplate`](prompts/CurrentFileName.idechatprompttemplate) - Current file name context.
- [`CurrentSelection.idechatprompttemplate`](prompts/CurrentSelection.idechatprompttemplate) - Selected source context.
- [`NoSelection.idechatprompttemplate`](prompts/NoSelection.idechatprompttemplate) - No-selection context.
- [`OriginalFile.idechatprompttemplate`](prompts/OriginalFile.idechatprompttemplate) - Original file context.
- [`Interfaces.idechatprompttemplate`](prompts/Interfaces.idechatprompttemplate) - Generated interface context.
- [`Issues.idechatprompttemplate`](prompts/Issues.idechatprompttemplate) - Issue context.
- [`AdditionalFiles.idechatprompttemplate`](prompts/AdditionalFiles.idechatprompttemplate) - Additional file context.
- [`NewKnowledge.idechatprompttemplate`](prompts/NewKnowledge.idechatprompttemplate) - New knowledge context.

#### Tool-Assisted Prompts

Prompts and guidance for tool-backed assistant modes.

- [`ToolAssistedBasicSystemPrompt.idechatprompttemplate`](prompts/ToolAssistedBasicSystemPrompt.idechatprompttemplate) - Tool-assisted base prompt.
- [`ToolAssistedReasoningSystemPrompt.idechatprompttemplate`](prompts/ToolAssistedReasoningSystemPrompt.idechatprompttemplate) - Tool-assisted reasoning prompt.
- [`ToolAssistedInQueryDetailedGuidelines.idechatprompttemplate`](prompts/ToolAssistedInQueryDetailedGuidelines.idechatprompttemplate) - Detailed in-query tool guidance.
- [`ToolAssistedInQueryShortGuidelines.idechatprompttemplate`](prompts/ToolAssistedInQueryShortGuidelines.idechatprompttemplate) - Short in-query tool guidance.
- [`InQueryDetailedGuidelines.idechatprompttemplate`](prompts/InQueryDetailedGuidelines.idechatprompttemplate) - Detailed in-query guidance.
- [`InQueryShortGuidelines.idechatprompttemplate`](prompts/InQueryShortGuidelines.idechatprompttemplate) - Short in-query guidance.

#### Agent Prompts

Agent-mode prompts and configuration resources.

- [`AgentSystemPromptAddition.idechatprompttemplate`](prompts/AgentSystemPromptAddition.idechatprompttemplate) - Agent system-prompt addition.
- [`AgentAdditionalContext.idechatprompttemplate`](prompts/AgentAdditionalContext.idechatprompttemplate) - Agent context template.

#### Coding Tool Templates

Templates for Xcode coding tools such as documentation, explanation, playground, and preview generation.

- [`CodingToolTemplateDocument.idechatprompttemplate`](prompts/CodingToolTemplateDocument.idechatprompttemplate) - Documentation coding-tool template.
- [`CodingToolTemplateExplain.idechatprompttemplate`](prompts/CodingToolTemplateExplain.idechatprompttemplate) - Explanation coding-tool template.
- [`CodingToolTemplateGeneratePlayground.idechatprompttemplate`](prompts/CodingToolTemplateGeneratePlayground.idechatprompttemplate) - Playground generation coding-tool template.
- [`CodingToolTemplateGeneratePreview.idechatprompttemplate`](prompts/CodingToolTemplateGeneratePreview.idechatprompttemplate) - Preview generation coding-tool template.
- [`GenerateDocumentation.idechatprompttemplate`](prompts/GenerateDocumentation.idechatprompttemplate) - Documentation generation prompt.
- [`GeneratePlayground.idechatprompttemplate`](prompts/GeneratePlayground.idechatprompttemplate) - Playground generation prompt.
- [`GeneratePreview.idechatprompttemplate`](prompts/GeneratePreview.idechatprompttemplate) - Preview generation prompt.

#### Search And Utility Prompts

Prompts for query expansion, search results, snippets, and chat title generation.

- [`ChatTitleResolver.idechatprompttemplate`](prompts/ChatTitleResolver.idechatprompttemplate) - Chat title resolver.
- [`Query.idechatprompttemplate`](prompts/Query.idechatprompttemplate) - Query wrapper.
- [`SearchResults.idechatprompttemplate`](prompts/SearchResults.idechatprompttemplate) - Search results wrapper.
- [`Snippets.idechatprompttemplate`](prompts/Snippets.idechatprompttemplate) - Snippet context.
- [`InstructionEmbeddingsQueryExpansion.idechatprompttemplate`](prompts/InstructionEmbeddingsQueryExpansion.idechatprompttemplate) - Instruction embedding query expansion.
- [`LocalInfillEmbeddingsQueryExpansion.idechatprompttemplate`](prompts/LocalInfillEmbeddingsQueryExpansion.idechatprompttemplate) - Local infill embedding query expansion.

### Additional Documentation

Markdown guides bundled with Xcode's intelligence resources.

#### Foundation And Core Frameworks

- [`FoundationModels-Using-on-device-LLM-in-your-app.md`](additional-documentation/FoundationModels-Using-on-device-LLM-in-your-app.md) - Foundation Models on-device LLM guide.
- [`Foundation-AttributedString-Updates.md`](additional-documentation/Foundation-AttributedString-Updates.md) - AttributedString updates.
- [`Swift-Concurrency-Updates.md`](additional-documentation/Swift-Concurrency-Updates.md) - Swift concurrency updates.
- [`Swift-InlineArray-Span.md`](additional-documentation/Swift-InlineArray-Span.md) - Swift InlineArray and Span guide.
- [`SwiftData-Class-Inheritance.md`](additional-documentation/SwiftData-Class-Inheritance.md) - SwiftData class inheritance guide.

#### UI And Design Frameworks

- [`SwiftUI-Implementing-Liquid-Glass-Design.md`](additional-documentation/SwiftUI-Implementing-Liquid-Glass-Design.md) - Liquid Glass in SwiftUI.
- [`UIKit-Implementing-Liquid-Glass-Design.md`](additional-documentation/UIKit-Implementing-Liquid-Glass-Design.md) - Liquid Glass in UIKit.
- [`AppKit-Implementing-Liquid-Glass-Design.md`](additional-documentation/AppKit-Implementing-Liquid-Glass-Design.md) - Liquid Glass in AppKit.
- [`WidgetKit-Implementing-Liquid-Glass-Design.md`](additional-documentation/WidgetKit-Implementing-Liquid-Glass-Design.md) - Liquid Glass in WidgetKit.
- [`SwiftUI-New-Toolbar-Features.md`](additional-documentation/SwiftUI-New-Toolbar-Features.md) - SwiftUI toolbar features.
- [`SwiftUI-Styled-Text-Editing.md`](additional-documentation/SwiftUI-Styled-Text-Editing.md) - SwiftUI styled text editing.
- [`SwiftUI-WebKit-Integration.md`](additional-documentation/SwiftUI-WebKit-Integration.md) - SwiftUI WebKit integration.
- [`SwiftUI-AlarmKit-Integration.md`](additional-documentation/SwiftUI-AlarmKit-Integration.md) - SwiftUI AlarmKit integration.

#### Intelligence And Accessibility

- [`Implementing-Visual-Intelligence-in-iOS.md`](additional-documentation/Implementing-Visual-Intelligence-in-iOS.md) - Visual Intelligence guide.
- [`Implementing-Assistive-Access-in-iOS.md`](additional-documentation/Implementing-Assistive-Access-in-iOS.md) - Assistive Access guide.

#### Platform-Specific Features

- [`Widgets-for-visionOS.md`](additional-documentation/Widgets-for-visionOS.md) - visionOS widgets guide.
- [`Swift-Charts-3D-Visualization.md`](additional-documentation/Swift-Charts-3D-Visualization.md) - Swift Charts 3D visualization guide.
- [`MapKit-GeoToolbox-PlaceDescriptors.md`](additional-documentation/MapKit-GeoToolbox-PlaceDescriptors.md) - MapKit GeoToolbox and PlaceDescriptors guide.

#### App Store And Commerce

- [`StoreKit-Updates.md`](additional-documentation/StoreKit-Updates.md) - StoreKit updates.
- [`AppIntents-Updates.md`](additional-documentation/AppIntents-Updates.md) - App Intents updates.

### Supporting Files

Top-level non-prompt resources copied from the same Xcode bundle resources directory.

- [`AgentVersions.plist`](support/AgentVersions.plist) - Agent model/version configuration.
- [`AppleXCNavigation-Heavy.ttf`](support/AppleXCNavigation-Heavy.ttf) - Bundled navigation font resource.
- [`ApprovedIntegrationModelPairings.plist`](support/ApprovedIntegrationModelPairings.plist) - Approved integration model pairings.
- [`Assets.car`](support/Assets.car) - Compiled asset catalog.
- [`IDEIntelligenceChat.xcplugindata`](support/IDEIntelligenceChat.xcplugindata) - Xcode intelligence chat plugin data.
- [`Info.plist`](support/Info.plist) - Bundle information plist.
- [`bert-estimate.vocab`](support/bert-estimate.vocab) - Embedding/token vocabulary resource.
- [`version.plist`](support/version.plist) - Bundle version plist.

## Boundary Notes

- This snapshot is extraction evidence, not accepted local skill behavior.
- Use official Apple documentation or owning Swift/Apple skills for implementation guidance.
- Compare `manifest.json` hashes before reading raw extracted files during drift review.

## Hash Inventory

| Category | Generated path | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `additional-documentation` | `additional-documentation/AppIntents-Updates.md` | 12226 | `d161014cfbf0a0d4...` |
| `additional-documentation` | `additional-documentation/AppKit-Implementing-Liquid-Glass-Design.md` | 13382 | `ed10b4cf4697bab2...` |
| `additional-documentation` | `additional-documentation/Foundation-AttributedString-Updates.md` | 6795 | `d439da765b3946bf...` |
| `additional-documentation` | `additional-documentation/FoundationModels-Using-on-device-LLM-in-your-app.md` | 12268 | `0a59e7ea806144eb...` |
| `additional-documentation` | `additional-documentation/Implementing-Assistive-Access-in-iOS.md` | 6421 | `24d9cba09d52cecf...` |
| `additional-documentation` | `additional-documentation/Implementing-Visual-Intelligence-in-iOS.md` | 10845 | `d7d5c86058198e39...` |
| `additional-documentation` | `additional-documentation/MapKit-GeoToolbox-PlaceDescriptors.md` | 9711 | `80f14c9d7480142c...` |
| `additional-documentation` | `additional-documentation/StoreKit-Updates.md` | 9496 | `79a980f784735439...` |
| `additional-documentation` | `additional-documentation/Swift-Charts-3D-Visualization.md` | 9245 | `8d81804565bf7bd9...` |
| `additional-documentation` | `additional-documentation/Swift-Concurrency-Updates.md` | 10675 | `0fbd5c2b5dd87710...` |
| `additional-documentation` | `additional-documentation/Swift-InlineArray-Span.md` | 8945 | `01e2630bccaecada...` |
| `additional-documentation` | `additional-documentation/SwiftData-Class-Inheritance.md` | 9863 | `d112124927d4f06a...` |
| `additional-documentation` | `additional-documentation/SwiftUI-AlarmKit-Integration.md` | 23618 | `34d7571b9f923a76...` |
| `additional-documentation` | `additional-documentation/SwiftUI-Implementing-Liquid-Glass-Design.md` | 8175 | `6365b71a65a15224...` |
| `additional-documentation` | `additional-documentation/SwiftUI-New-Toolbar-Features.md` | 6633 | `3636e0b20a2c3a32...` |
| `additional-documentation` | `additional-documentation/SwiftUI-Styled-Text-Editing.md` | 10905 | `b7c09273cee7ff17...` |
| `additional-documentation` | `additional-documentation/SwiftUI-WebKit-Integration.md` | 12414 | `2320fe764030be4a...` |
| `additional-documentation` | `additional-documentation/UIKit-Implementing-Liquid-Glass-Design.md` | 10008 | `f57afa408d4fd245...` |
| `additional-documentation` | `additional-documentation/WidgetKit-Implementing-Liquid-Glass-Design.md` | 7704 | `a2c7e5e849002a34...` |
| `additional-documentation` | `additional-documentation/Widgets-for-visionOS.md` | 8743 | `a1710b92f027d27c...` |
| `prompt-template` | `prompts/AdditionalFiles.idechatprompttemplate` | 248 | `cf8f9f44ee0e689f...` |
| `prompt-template` | `prompts/AgentAdditionalContext.idechatprompttemplate` | 481 | `37c2251a253f1adc...` |
| `prompt-template` | `prompts/AgentSystemPromptAddition.idechatprompttemplate` | 4324 | `65932d67ab13e88d...` |
| `prompt-template` | `prompts/BasicSystemPrompt.idechatprompttemplate` | 3448 | `38e4a18f8bcf3768...` |
| `prompt-template` | `prompts/ChatTitleResolver.idechatprompttemplate` | 1735 | `4998a79611cfa839...` |
| `prompt-template` | `prompts/CodingToolTemplateDocument.idechatprompttemplate` | 764 | `24cb896548eaae52...` |
| `prompt-template` | `prompts/CodingToolTemplateExplain.idechatprompttemplate` | 393 | `1de12b11f3dcfc35...` |
| `prompt-template` | `prompts/CodingToolTemplateGeneratePlayground.idechatprompttemplate` | 990 | `598310e1d729acf7...` |
| `prompt-template` | `prompts/CodingToolTemplateGeneratePreview.idechatprompttemplate` | 1032 | `a7d8dfc580372aa4...` |
| `prompt-template` | `prompts/ContextItems.idechatprompttemplate` | 185 | `cdb04d6bed70c2ac...` |
| `prompt-template` | `prompts/CurrentFile.idechatprompttemplate` | 175 | `6efe3a3e43520eea...` |
| `prompt-template` | `prompts/CurrentFileAbbreviated.idechatprompttemplate` | 402 | `44d94ee05633438c...` |
| `prompt-template` | `prompts/CurrentFileName.idechatprompttemplate` | 62 | `47a8023194b54d29...` |
| `prompt-template` | `prompts/CurrentSelection.idechatprompttemplate` | 110 | `9d4a2db04e2d9a6b...` |
| `prompt-template` | `prompts/FastApplyIntegratorSystemPrompt.idechatprompttemplate` | 107 | `ec07524c36e05dd3...` |
| `prompt-template` | `prompts/FastApplyIntegratorUserPrompt.idechatprompttemplate` | 419 | `33262f52b1cf1049...` |
| `prompt-template` | `prompts/GenerateDocumentation.idechatprompttemplate` | 152 | `c0435f5eba5cc751...` |
| `prompt-template` | `prompts/GeneratePlayground.idechatprompttemplate` | 209 | `ae39f42972a5b893...` |
| `prompt-template` | `prompts/GeneratePreview.idechatprompttemplate` | 1715 | `2bab2bb1a99d8589...` |
| `prompt-template` | `prompts/InQueryDetailedGuidelines.idechatprompttemplate` | 984 | `9f98ad888d608c0a...` |
| `prompt-template` | `prompts/InQueryShortGuidelines.idechatprompttemplate` | 137 | `f86352b63e911de0...` |
| `prompt-template` | `prompts/InstructionEmbeddingsQueryExpansion.idechatprompttemplate` | 1475 | `9f3c1a8e3c31f808...` |
| `prompt-template` | `prompts/IntegratorSystemPrompt.idechatprompttemplate` | 1056 | `307a3dc4a09b45bb...` |
| `prompt-template` | `prompts/IntegratorUserPrompt.idechatprompttemplate` | 64 | `29d1954bfd2906e9...` |
| `prompt-template` | `prompts/Interfaces.idechatprompttemplate` | 203 | `2e57593e407e3735...` |
| `prompt-template` | `prompts/Issues.idechatprompttemplate` | 134 | `b8bd9ab9e65d5879...` |
| `prompt-template` | `prompts/LocalInfillEmbeddingsQueryExpansion.idechatprompttemplate` | 1439 | `e35bb7dffa356f3c...` |
| `prompt-template` | `prompts/NewCodeIntegratorSystemPrompt.idechatprompttemplate` | 956 | `870492827726310e...` |
| `prompt-template` | `prompts/NewCodeIntegratorUserPrompt.idechatprompttemplate` | 79 | `a53e95ec183c764f...` |
| `prompt-template` | `prompts/NewKnowledge.idechatprompttemplate` | 144 | `a2432133b42dfb75...` |
| `prompt-template` | `prompts/NoSelection.idechatprompttemplate` | 31 | `f41f1ed281d928a0...` |
| `prompt-template` | `prompts/OriginalFile.idechatprompttemplate` | 72 | `28ab02960be05db3...` |
| `prompt-template` | `prompts/PlannerExecutorStyleNoClassify.idechatprompttemplate` | 5568 | `53c8a5dcb3ea3e78...` |
| `prompt-template` | `prompts/PlannerExecutorStylePlannerSystemPrompt-gpt_5.idechatprompttemplate` | 12436 | `ede26b62ec4ce87d...` |
| `prompt-template` | `prompts/PlannerExecutorStylePlannerSystemPrompt.idechatprompttemplate` | 10368 | `c4081552f740768c...` |
| `prompt-template` | `prompts/Query.idechatprompttemplate` | 33 | `7bf61cb6d428f298...` |
| `prompt-template` | `prompts/ReasoningSystemPrompt.idechatprompttemplate` | 2795 | `afdb316f3a34cba7...` |
| `prompt-template` | `prompts/SearchResults.idechatprompttemplate` | 185 | `0ad610a45ab6a5cf...` |
| `prompt-template` | `prompts/Snippets.idechatprompttemplate` | 158 | `76135c5e5f11e936...` |
| `prompt-template` | `prompts/TextEditorToolSystemPrompt.idechatprompttemplate` | 3802 | `5997f1d930c829d1...` |
| `prompt-template` | `prompts/ToolAssistedBasicSystemPrompt.idechatprompttemplate` | 3994 | `cf73ca6e68775f9a...` |
| `prompt-template` | `prompts/ToolAssistedInQueryDetailedGuidelines.idechatprompttemplate` | 1560 | `463b461d5eba69cf...` |
| `prompt-template` | `prompts/ToolAssistedInQueryShortGuidelines.idechatprompttemplate` | 137 | `f86352b63e911de0...` |
| `prompt-template` | `prompts/ToolAssistedReasoningSystemPrompt.idechatprompttemplate` | 3374 | `1c36d7193dfb59a4...` |
| `prompt-template` | `prompts/VariantASystemPrompt.idechatprompttemplate` | 4144 | `445db733ee7c05c8...` |
| `prompt-template` | `prompts/VariantBSystemPrompt.idechatprompttemplate` | 3015 | `5bfa620c91bced62...` |
| `support-file` | `support/AgentVersions.plist` | 997 | `6b24e61a719cddcb...` |
| `support-file` | `support/AppleXCNavigation-Heavy.ttf` | 35156 | `0935758c2aaba4ea...` |
| `support-file` | `support/ApprovedIntegrationModelPairings.plist` | 1101 | `bfb6546018b00f59...` |
| `support-file` | `support/Assets.car` | 419176 | `d4a969c7769611aa...` |
| `support-file` | `support/IDEIntelligenceChat.xcplugindata` | 20437 | `338cdb7b7f9bee0a...` |
| `support-file` | `support/Info.plist` | 847 | `d342e5dc28facde3...` |
| `support-file` | `support/bert-estimate.vocab` | 231508 | `07eced375cec144d...` |
| `support-file` | `support/version.plist` | 473 | `cd66ffbed7478518...` |
