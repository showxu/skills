# Interaction Design Canonical Model Template

## Header

- Feature or journey:
- Source requirement:
- Owner:
- Status: Draft | In review | Approved
- Last updated:

## Scope

- Interaction slice covered:
- Explicit exclusions:
- Primary users or roles:
- Product stage: interaction-design.

## Canonical Interaction Model

This block is the canonical interaction-design source of truth. Keep IDs
stable after review because requirements traceability, downstream projections,
and prototype coverage verification may link to them. Human-readable tables
below may summarize this model, but they must not contradict it.

```yaml
interaction_model:
  version: "1"
  feature:
  source_requirements: []
  assumptions: []
  behavior:
    flows:
      - id:
        name:
        goal:
        related_requirements: []
        entry_point:
        primary_path: []
        alternate_paths: []
        failure_paths: []
        success_outcome:
        affected_screens: []
        relevant_business_rules: []
        open_decisions: []
        related_user_stories: []
        related_acceptance_criteria: []
    screens:
      - id:
        name:
        purpose:
        screen_intent: monitor | find | complete_process | compare | configure | consume | other
        sections: []
        screen_anatomy:
          primary_regions: []
          persistent_regions: []
          transient_regions: []
          hierarchy_notes: []
        wireframe_semantics:
          content_priority: []
          control_groups: []
          placement_intent: []
          relationship_notes: []
        entry_conditions: []
        exit_conditions: []
        states: []
        relevant_components: []
    state_machines:
      - id:
        scope:
        states: []
        events: []
        guards: []
        impossible_states: []
        default_recovery:
        no_dead_end_check:
    states:
      - id:
        screen_id:
        type: default | loading | empty | error | success | validation_error | disabled | permission_denied | submitting | processing | confirmation | other
        description:
        entry_condition:
        exit_condition:
        visible_elements: []
        available_actions: []
        disabled_reason:
        recovery_actions: []
    actions:
      - id:
        label:
        intent:
        trigger:
        source_screen:
        source_state:
        preconditions: []
        affected_components: []
        invoked_transition:
        validation_rules: []
        business_rules: []
        behavior:
        resulting_screen:
        resulting_state:
        feedback:
    transitions:
      - id:
        action_id:
        from_screen:
        from_state:
        to_screen:
        to_state:
        trigger:
        conditions: []
        success_path:
        failure_path:
        loading_or_processing_behavior:
        feedback:
        recovery_path:
    components:
      - id:
        type:
        purpose:
        data_displayed: []
        user_actions: []
        validation_rules: []
        states: []
    validation_rules:
      - id:
        scope: field | form | business | permission | other
        component_id:
        rule:
        trigger:
        affected_actions: []
        failure_state:
        feedback_pattern:
        error_feedback:
        recovery_behavior:
        related_acceptance_criteria: []
    business_rules:
      - id:
        rule:
        affected_flows: []
        affected_components: []
        related_acceptance_criteria: []
    system_permission_flows:
      - id:
        platform:
        permission:
        authorization_subject:
        trigger:
        blocked_state:
        request_or_handoff_action:
        system_response:
        granted_transition:
        denied_or_cancelled_transition:
        recovery_actions: []
        reentry_behavior:
        fallback_behavior:
        external_build_constraints: []
    edge_cases:
      - id:
        scenario:
        expected_behavior:
        affected_screen_or_flow:
        recovery_behavior:
        fallback_behavior:
        status: handled | open | out_of_scope
        related_user_stories: []
        related_acceptance_criteria: []
    feedback_patterns:
      - id:
        event:
        feedback_type: inline_error | banner | alert | confirmation | loading_indicator | disabled_state | success_acknowledgement | retry_affordance | cancellation_affordance | other
        message_intent:
        affected_actions: []
        recovery_affordance:
    loading_strategy:
      screens: []
      blank_state_allowed: false
      skeleton_or_spinner_intent:
      optimistic_ui_allowed: false
      layout_or_scroll_preservation:
    gesture_model:
      gestures: []
      fallback_actions: []
      commit_or_cancel_rules: []
    search_or_filter_model:
      query_scope:
      zero_results_behavior:
      partial_results_behavior:
      clear_or_reset_behavior:
    interaction_options:
      - id:
        name:
        scope:
        model_ids: []
        pattern:
        tradeoffs: []
        recommendation:
        decision_status: selected | rejected | open
        rationale:
    open_decisions:
      - id:
        question:
        affected_requirements: []
        affected_flows: []
        affected_screens: []
        affected_states: []
        affected_actions: []
        affected_acceptance_criteria: []
        options: []
        owner:
        needed_by:
        blocks_interaction_design: false
        blocks_projection: false
        blocks_prototype_generation: false
        blocks_prototype_verification: false
        fallback_allowed: false
        recommended_resolver:
        blocked_artifacts: []
        impact_if_unresolved:
  platform:
    target_surface: ios_app | mobile_web | ipados_app | macos_app | desktop_web | watchos_app | tvos_app | visionos_app | other
    adapter: apple_ios | apple_ipados | apple_macos | apple_watchos | apple_tvos | apple_visionos | web | other
    implementation_claim: none | native_later | web_later | implementation_ready
    device_bezel:
      type: iphone | ipad | macbook | imac | apple_watch | apple_tv | browser_window | none
      source: apple_design_resource | generated_css | none
      resource_id:
    input_methods: []
    platform_constraints:
      - safe_area_aware
      - dynamic_type_compatible
      - minimum_touch_target
      - keyboard_accessible
    adaptation_notes: []
    convention_review:
      platform_convention_status: not_requested | needed | in_review | reviewed | blocked
      ux_quality_status: not_requested | needed | in_review | reviewed | blocked
      findings_to_resolve: []
      accepted_delta_links: []
    scene_presentations:
      - screen_id:
        state_id:
        container_primitive: List | Form | NavigationStack | NavigationSplitView | Window | TabView | Sheet | Popover | FocusGrid | CompactList | browser_document | other
        navigation_context:
        regions:
          - region_id:
            component_id:
            primitive:
            placement: top_bar | toolbar | list_row | form_section | bottom_bar | sheet_body | sidebar | inspector | content | other
            emphasis: primary | secondary | destructive | neutral | disabled
    action_presentations:
      - action_id:
        primitive: Button | ToolbarItem | row_tap_affordance | swipe_action | context_menu_item | keyboard_shortcut | menu_command | picker_option | other
        placement:
        affordance:
        emphasis: primary | secondary | destructive | neutral | disabled
        input_methods: []
    transition_presentations:
      - transition_id:
        primitive: navigation_push | sheet_present | sheet_dismiss | popover_present | alert_present | tab_switch | sidebar_selection | window_open | inline_state_change | focus_move | other
        animation_or_presentation_style:
        platform_notes:
    feedback_presentations:
      - feedback_id:
        primitive: inline_error | banner | alert | confirmation_dialog | progress_view | disabled_control | success_toast | retry_button | other
        placement:
    validation_presentations:
      - validation_id:
        primitive: inline_field_error | form_summary | disabled_submit | confirmation_dialog | other
        placement:
    coverage_gaps:
      - behavior_id:
        behavior_type: flow | screen | state | action | transition | component | validation | feedback | edge_case | open_decision
        reason:
        blocks_projection: false
        acceptable_placeholder:
    projection_notes:
      - Rendered artifacts must use platform bindings as projection hints and must not create product behavior.
      - Visual polish, exact spacing, colors, typography, and brand treatment belong in design/style artifacts, not this model.
  traceability:
    requirements: []
    user_stories: []
    acceptance_criteria: []
    links:
      - model_id:
        model_layer: behavior | platform
        model_type:
        requirements: []
        user_stories: []
        acceptance_criteria: []
        discovery_evidence: []
        downstream_artifacts: []
  coverage_expectations:
    required_flows: []
    required_screens: []
    required_states_by_screen: []
    required_interactions: []
    required_platform_bindings: []
    static_projection_allowed: []
    fake_allowed: []
    out_of_scope: []
  product_prototype_contract:
    purpose:
    source_model_ids: []
    required_screens: []
    required_flows: []
    required_states: []
    required_click_paths: []
    required_validation_and_feedback: []
    required_recovery_paths: []
    required_permission_handoffs: []
    required_platform_expression: []
    explicit_non_goals: []
    blocked_by_open_decisions: []
    allowed_placeholders: []
    coverage_verification_notes: []
  prototype_projection_controls:
    purpose:
    placement_rule:
    source_of_truth_rule:
    controls:
      - id:
        exposes_behavior_ids: []
        control_type: reviewer_only_state_switcher | reviewer_only_failure_injection | reviewer_only_navigation_shortcut | other
        real_trigger:
        not_product_ui: true
  projection_targets:
    - target: figma_product_prototype | html_product_prototype | prototype_review | other
      role: prototype_generation | prototype_review | design_review_aid
      source_model_ids: []
      target_constraints_notes: []
      allowed_assumptions: []
      prohibited_inventions: []
      validation_checkpoints: []
  projection_gaps:
    - id:
      gap_type: missing_state | missing_destination | target_constraint | source_conflict | open_decision | missing_platform_binding | other
      affected_model_ids: []
      owner:
      blocks_projection: false
      blocks_prototype_generation: false
      blocks_prototype_verification: false
      acceptable_placeholder:
      impact_if_unresolved:
  downstream_handoff:
    prototype_projection_notes: []
    figma_projection_notes: []
    html_prototype_notes: []
    prototype_review_notes: []
    projection_gap_links: []
    review_delta_links: []
```

## Flow Map

| Flow ID | Name | Trigger | End condition |
| --- | --- | --- | --- |
| F-1 |  |  |  |

## Primary Flow Steps

### Flow: <name>

| Step | User action | System response | Resulting state | Notes |
| --- | --- | --- | --- | --- |
| 1 |  |  |  |  |

## State And Transition Rules

| State | Entry condition | Allowed actions | Exit condition |
| --- | --- | --- | --- |
|  |  |  |  |

## State Machines

Use this section when a flow has meaningful state guards, impossible states,
async behavior, or gesture/undo/cancel rules. Do not turn this into
app architecture.

| State machine | Scope | Events | Guards | Impossible states | Recovery / no-dead-end check |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## Screen Anatomy And Wireframe Semantics

Describe product meaning and behavior placement. Do not turn this into visual
design polish, CSS layout, Figma operations, or app rendering work.

| Screen | Primary regions | Persistent / transient regions | Control groups | Placement intent | Projection notes |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## Platform Expression

Describe platform primitives and device bezel choices as bindings to existing
`behavior` IDs. Do not redefine behavior, transition destinations, business
rules, visual style, exact spacing, brand colors, typography, or renderer
implementation.

| Behavior ID | Binding type | Platform primitive | Placement / presentation | Notes |
| --- | --- | --- | --- | --- |
| screen / state / component / action / transition / feedback ID | scene / action / transition / feedback |  |  |  |

## Platform Coverage Gaps

Use this when a behavior item exists but the current platform expression or
projection intentionally does not represent it.

| Behavior ID | Type | Gap reason | Placeholder allowed | Blocks projection |
| --- | --- | --- | --- | --- |
|  |  |  | Yes / No | Yes / No |

## Edge Cases

| Case | Trigger | Expected behavior | Resulting state |
| --- | --- | --- | --- |
|  |  |  |  |

## Error And Recovery Behavior

| Scenario | Error behavior | Recovery path |
| --- | --- | --- |
|  |  |  |

## Loading, Processing, And Disabled Behavior

| Screen / state | Trigger | Expected behavior | Recovery or exit | Notes |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Search, Filter, And Gesture Behavior

| Model | Scope | Trigger | Commit / cancel rule | Fallback action | Platform review needed |
| --- | --- | --- | --- | --- | --- |
| Search / filter / gesture |  |  |  |  |  |

## Empty And Loading States

| State | Trigger | Expected behavior |
| --- | --- | --- |
| Empty |  |  |
| Loading |  |  |

## Permissions And Visibility

| Role or permission | Allowed behavior | Restricted behavior |
| --- | --- | --- |
|  |  |  |

## System-Mediated Permission Flows

Use this section when a platform permission or external system setting blocks a
user task. Describe product behavior, not API calls or implementation details.
Permission handoff behavior must be recorded per platform because macOS, iOS,
iPadOS, watchOS, tvOS, visionOS, web, and desktop OSes expose different system
surfaces and recovery paths.

| Platform | Permission | Authorization subject | Blocked state | User action / handoff | System response | Recovery / fallback | Re-entry behavior |
| --- | --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |  |

## Decision Needed

| Decision | Options | Recommended option | Owner | Needed by |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Traceability

| Interaction item | Requirement | Story link | Acceptance link |
| --- | --- | --- | --- |
|  |  |  |  |

## Product Prototype Contract

This is the product-owned prototype design output. It states what a rendered
Figma, HTML, or review prototype must represent. It does not choose a renderer,
create files, define final visual design, or become a second behavior source.

| Contract item | Required coverage | Source model IDs | Blocking gaps / open decisions |
| --- | --- | --- | --- |
| Screens |  |  |  |
| Flows / click paths |  |  |  |
| States |  |  |  |
| Validation and feedback |  |  |  |
| Recovery / edge cases |  |  |  |
| Permission handoffs |  |  |  |

## Projection Coverage

This is product-owned coverage intent for downstream projections. It does not
choose a renderer, create artifacts, or make rendered artifacts sources of
truth.

| Target | Required model coverage | Allowed assumptions | Prohibited inventions | Blocking gaps |
| --- | --- | --- | --- | --- |
| Figma product prototype / HTML product prototype / prototype review / other |  |  |  |  |

## Prototype Projection Controls

Use this only when a rendered prototype needs reviewer controls to reach
modeled states that would normally be caused by system events, API outcomes,
permissions, timers, or fixture setup. These controls are not product UI and
must not be recorded as canonical action or transition triggers.

| Control | Exposes model IDs | Real trigger / event represented | Placement | Product UI? |
| --- | --- | --- | --- | --- |
|  |  |  | reviewer panel / hidden review drawer / coverage tool | No |

## Handoff Notes

- Prototype projection considerations:
- Figma product prototype considerations:
- HTML product prototype / review artifact considerations:
- Prototype review considerations:
- Story authoring considerations:
- Acceptance criteria considerations:

## Open Questions

| Question | Why it matters | Owner |
| --- | --- | --- |
|  |  |  |

## Quality Check

- One canonical `interaction_model` block is present.
- The model includes flows, screens, states, actions, transitions, components,
  screen anatomy, wireframe semantics, validation rules, business rules,
  feedback patterns, state-machine semantics, edge cases, handoff notes, and
  traceability links when available.
- Platform-aware work includes `platform` with target surface, adapter,
  device bezel, input methods, constraints, adaptation notes, presentation
  bindings, and convention guidance/review status.
- `platform` references `behavior` IDs only. It does not define new flows,
  screens, states, actions, transitions, validation, feedback, recovery, or
  business rules.
- `platform.action_presentations` expose existing actions as controls or
  affordances and do not include transition destinations.
- `platform.transition_presentations` reference existing transitions and
  describe platform presentation only.
- Official Apple design resources can appear as `device_bezel` or platform
  primitive/resource references, not as product behavior.
- Exact margins, colors, typography sizes, corner radii, brand polish, and
  component visual specifications are excluded from interaction design and
  belong in design/style artifacts.
- Steps are observable and unambiguous.
- States, actions, and transitions are explicit and non-duplicative: actions
  describe user/system triggers, transitions describe screen or state changes.
- State machines include guards, impossible states, and recovery/no-dead-end
  checks when those risks are material.
- Edge and recovery states are covered when relevant.
- Loading, disabled, validation-error, permission-denied, submitting, and
  processing behavior are covered when relevant, or intentionally omitted with
  a reason.
- Permissions are documented where behavior differs by role.
- System-mediated permission flows document the platform, permission, authorization
  subject, blocked/granted/denied behavior, handoff action, recovery/fallback,
  and re-entry behavior when a platform permission blocks the task.
- Product prototype contract is present when downstream prototype generation or
  review is in scope, and every required prototype item links back to model IDs.
- Projection coverage expectations, target notes, and gaps are derived from
  the interaction model and do not create a second source of truth.
- Concrete renderer choices, rendered artifact details, visual design
  instructions, styling source rules, and code plans are excluded.
- Open decisions state whether they block interaction design, downstream
  projection, prototype generation, prototype verification, or none of those,
  and whether fallback is allowed.
