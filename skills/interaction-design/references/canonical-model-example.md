# Interaction Design Canonical Model Example: Saved Report Filters

## Header

- Feature or journey: Saved report filters
- Source requirement: `PR-1` through `PR-5`
- Owner: Product
- Status: Draft
- Last updated: 2026-05-10

## Scope

- Interaction slice covered: Save, apply, and recover from errors for personal
  saved report filters.
- Explicit exclusions: Team sharing, final visual design, implementation.
- Primary users or roles: Analyst.
- Product stage: interaction-design.

## Canonical Interaction Model

```yaml
interaction_model:
  version: "1"
  feature: Saved report filters
  source_requirements: [PR-1, PR-2, PR-3, PR-4, PR-5]
  assumptions:
    - Personal saved filters are scoped to one report.
    - Applying a saved filter replaces the current active filter set unless an open decision changes it.

  behavior:
    flows:
      - id: F-SAVE-FILTER
        name: Save current filter set
        goal: Let an analyst preserve the current report filter criteria.
        related_requirements: [PR-1, PR-2]
        entry_point: Report page with active filters.
        primary_path: [A-OPEN-SAVE, A-SUBMIT-SAVE]
        alternate_paths: [A-CANCEL-SAVE]
        failure_paths: [EC-DUPLICATE-NAME]
        success_outcome: New saved filter appears in the saved filters list.
        affected_screens: [S-REPORT, S-SAVE-FILTER]
        relevant_business_rules: [BR-PERSONAL-SCOPE]
        open_decisions: []
        related_user_stories: [US-1]
        related_acceptance_criteria: [AC-1, AC-2]
      - id: F-APPLY-FILTER
        name: Apply saved filter
        goal: Let an analyst switch the report to a previously saved filter set.
        related_requirements: [PR-3]
        entry_point: Saved filters list.
        primary_path: [A-OPEN-SAVED-FILTERS, A-APPLY-FILTER]
        alternate_paths: [A-RETRY-APPLY]
        failure_paths: [EC-APPLY-FAILED]
        success_outcome: Report refreshes with the selected saved filter criteria.
        affected_screens: [S-REPORT, S-SAVED-FILTERS]
        relevant_business_rules: [BR-PRESERVE-REPORT-ON-FAILURE]
        open_decisions: [D-APPLY-SEMANTICS]
        related_user_stories: [US-2]
        related_acceptance_criteria: [AC-3, AC-4]

    screens:
      - id: S-REPORT
        name: Report page
        purpose: View report results and access saved filter controls.
        screen_intent: monitor
        sections: [active filter summary, saved filter entry controls, report results]
        screen_anatomy:
          primary_regions: [report results]
          persistent_regions: [active filter summary, saved filter entry controls]
          transient_regions: [save success acknowledgement]
          hierarchy_notes: [report content remains primary; saved-filter controls support repeat setup]
        wireframe_semantics:
          content_priority: [report results, active filter summary, saved-filter actions]
          control_groups: [active filter controls, saved filter actions]
          placement_intent: [saved-filter actions stay near active filter summary]
          relationship_notes: [saving current filters does not change report data]
        entry_conditions: [report is accessible to user]
        exit_conditions: [user opens saved filters, user opens save flow, user navigates away]
        states: [ST-REPORT-READY, ST-REPORT-FILTER-APPLIED]
        relevant_components: [C-SAVED-FILTERS-ENTRY, C-SAVE-CURRENT-FILTERS]
      - id: S-SAVED-FILTERS
        name: Saved filters list
        purpose: Browse and apply personal saved filters for the current report.
        screen_intent: find
        sections: [panel header, filter list, empty state, error message]
        screen_anatomy:
          primary_regions: [filter list]
          persistent_regions: [close affordance]
          transient_regions: [loading feedback, empty guidance, recoverable error]
          hierarchy_notes: [row apply action is primary; recovery actions are visible on error]
        wireframe_semantics:
          content_priority: [saved filter name, last updated metadata, apply action]
          control_groups: [row primary action, recovery actions]
          placement_intent: [apply action belongs to each saved filter row]
          relationship_notes: [loading and error states protect the previous report state]
        entry_conditions: [user opens saved filters]
        exit_conditions: [filter applied, panel closed, recovery path selected]
        states: [ST-SAVED-FILTERS-LIST, ST-SAVED-FILTERS-LOADING, ST-SAVED-FILTERS-EMPTY, ST-SAVED-FILTERS-ERROR]
        relevant_components: [C-SAVED-FILTER-ROW]
      - id: S-SAVE-FILTER
        name: Save filter
        purpose: Name and save the current filter criteria.
        screen_intent: complete_process
        sections: [name field, validation message, save action, cancel action]
        screen_anatomy:
          primary_regions: [name entry form]
          persistent_regions: [save action, cancel action]
          transient_regions: [validation feedback, saving feedback]
          hierarchy_notes: [name entry and save confirmation are the only primary tasks]
        wireframe_semantics:
          content_priority: [name field, validation feedback, save action, cancel action]
          control_groups: [text input, modal actions]
          placement_intent: [validation feedback appears with the name field]
          relationship_notes: [cancel leaves active filters unchanged]
        entry_conditions: [user chooses save current filters]
        exit_conditions: [save succeeds, user cancels]
        states: [ST-SAVE-READY, ST-SAVE-VALIDATION-ERROR, ST-SAVE-SUBMITTING]
        relevant_components: [C-FILTER-NAME]

    states:
      - id: ST-REPORT-READY
        screen_id: S-REPORT
        type: default
        description: Report is loaded and saved filter entry controls are available.
        entry_condition: report data loaded
        exit_condition: user opens saved filter controls or navigates away
        visible_elements: [saved filters entry, save current filters action, active filter summary, report results]
        available_actions: [A-OPEN-SAVED-FILTERS, A-OPEN-SAVE]
      - id: ST-REPORT-FILTER-APPLIED
        screen_id: S-REPORT
        type: success
        description: Report has refreshed with the selected saved filter criteria.
        entry_condition: T-APPLY-SUCCESS completes
        exit_condition: user changes filter state or opens another filter
        visible_elements: [selected saved filter label, active filter summary, report results]
        available_actions: [A-OPEN-SAVED-FILTERS, A-OPEN-SAVE]
      - id: ST-SAVED-FILTERS-LIST
        screen_id: S-SAVED-FILTERS
        type: default
        description: Personal saved filter rows are visible.
        visible_elements: [filter rows, apply actions]
        available_actions: [A-APPLY-FILTER]
      - id: ST-SAVED-FILTERS-LOADING
        screen_id: S-SAVED-FILTERS
        type: loading
        description: A saved filter is being applied.
        visible_elements: [applying feedback, protected previous report state]
        available_actions: []
      - id: ST-SAVED-FILTERS-ERROR
        screen_id: S-SAVED-FILTERS
        type: error
        description: Applying the saved filter failed.
        visible_elements: [recoverable error message, retry action, dismiss action]
        available_actions: [A-RETRY-APPLY]
        recovery_actions: [A-RETRY-APPLY]
      - id: ST-SAVE-READY
        screen_id: S-SAVE-FILTER
        type: default
        description: Save form is ready for filter name input.
        visible_elements: [name field, save action, cancel action]
        available_actions: [A-SUBMIT-SAVE, A-CANCEL-SAVE]
      - id: ST-SAVE-VALIDATION-ERROR
        screen_id: S-SAVE-FILTER
        type: validation_error
        description: Name validation failed.
        visible_elements: [name field, inline validation message, save action, cancel action]
        available_actions: [A-SUBMIT-SAVE, A-CANCEL-SAVE]
        recovery_actions: [A-SUBMIT-SAVE, A-CANCEL-SAVE]

    actions:
      - id: A-OPEN-SAVED-FILTERS
        label: Saved filters
        intent: Reveal personal saved filters for the current report.
        trigger: User selects saved filters entry.
        source_screen: S-REPORT
        source_state: ST-REPORT-READY
        preconditions: [report is loaded]
        affected_components: [C-SAVED-FILTERS-ENTRY]
        invoked_transition: T-OPEN-SAVED-FILTERS
        behavior: Show saved filters without changing active report criteria.
        resulting_screen: S-SAVED-FILTERS
        resulting_state: ST-SAVED-FILTERS-LIST
        feedback: Saved filters list appears.
      - id: A-OPEN-SAVE
        label: Save current filters
        intent: Start naming and saving the current report filter criteria.
        trigger: User selects save current filters.
        source_screen: S-REPORT
        source_state: ST-REPORT-READY
        preconditions: [report is loaded, user can create personal saved filters]
        affected_components: [C-SAVE-CURRENT-FILTERS]
        invoked_transition: T-OPEN-SAVE
        validation_rules: []
        business_rules: [BR-PERSONAL-SCOPE]
        behavior: Open the save filter form with an empty required name field.
        resulting_screen: S-SAVE-FILTER
        resulting_state: ST-SAVE-READY
        feedback: Save form appears without changing active report filters.
      - id: A-SUBMIT-SAVE
        label: Save
        intent: Persist the current filter criteria under the entered personal name.
        trigger: User submits save.
        source_screen: S-SAVE-FILTER
        source_state: ST-SAVE-READY
        preconditions: [name is present, current filter criteria are saveable]
        affected_components: [C-FILTER-NAME]
        invoked_transition: T-SAVE-SUCCESS
        validation_rules: [VR-NAME-REQUIRED, VR-DUPLICATE-NAME]
        business_rules: [BR-PERSONAL-SCOPE]
        behavior: Persist a personal saved filter for the current report.
        resulting_screen: S-SAVED-FILTERS
        resulting_state: ST-SAVED-FILTERS-LIST
        feedback: Success acknowledgement confirms saved filter creation.
      - id: A-CANCEL-SAVE
        label: Cancel
        intent: Exit save form without creating a saved filter.
        trigger: User cancels save.
        source_screen: S-SAVE-FILTER
        source_state: ST-SAVE-READY
        preconditions: []
        invoked_transition: T-CANCEL-SAVE
        behavior: Close the save form without changing report filters.
        resulting_screen: S-REPORT
        resulting_state: ST-REPORT-READY
        feedback: Report remains unchanged.
      - id: A-APPLY-FILTER
        label: Apply
        intent: Replace active filter criteria with the selected saved filter.
        trigger: User selects apply on a saved filter row.
        source_screen: S-SAVED-FILTERS
        source_state: ST-SAVED-FILTERS-LIST
        preconditions: [selected filter still exists, report can refresh]
        affected_components: [C-SAVED-FILTER-ROW]
        invoked_transition: T-APPLY-START
        business_rules: [BR-PRESERVE-REPORT-ON-FAILURE]
        behavior: Apply selected saved filter to the report.
        resulting_screen: S-SAVED-FILTERS
        resulting_state: ST-SAVED-FILTERS-LOADING
        feedback: Applying feedback appears while previous report state is preserved.
      - id: A-RETRY-APPLY
        label: Retry
        intent: Retry applying the selected saved filter after a recoverable failure.
        trigger: User selects retry after apply failure.
        source_screen: S-SAVED-FILTERS
        source_state: ST-SAVED-FILTERS-ERROR
        preconditions: [selected filter still exists]
        invoked_transition: T-APPLY-START
        behavior: Retry applying the selected saved filter.
        resulting_screen: S-SAVED-FILTERS
        resulting_state: ST-SAVED-FILTERS-LOADING
        feedback: Retry feedback replaces the recoverable error.

    transitions:
      - id: T-OPEN-SAVED-FILTERS
        action_id: A-OPEN-SAVED-FILTERS
        from_screen: S-REPORT
        from_state: ST-REPORT-READY
        to_screen: S-SAVED-FILTERS
        to_state: ST-SAVED-FILTERS-LIST
        trigger: saved filters selected
        conditions: [report is loaded]
        success_path: Saved filters list is available.
        failure_path: Remain on report page and explain unavailable action.
        feedback: Saved filters list opens.
        recovery_path: User can dismiss the list.
      - id: T-OPEN-SAVE
        action_id: A-OPEN-SAVE
        from_screen: S-REPORT
        from_state: ST-REPORT-READY
        to_screen: S-SAVE-FILTER
        to_state: ST-SAVE-READY
        trigger: save current filters selected
        conditions: [user can save personal filters]
        success_path: Save filter form appears ready for input.
        failure_path: Remain on report page and explain unavailable action.
        feedback: Save form opens.
        recovery_path: Cancel returns to report page without changing filters.
      - id: T-SAVE-SUCCESS
        action_id: A-SUBMIT-SAVE
        from_screen: S-SAVE-FILTER
        from_state: ST-SAVE-READY
        to_screen: S-SAVED-FILTERS
        to_state: ST-SAVED-FILTERS-LIST
        trigger: valid save submitted
        conditions: [name passes validation]
        success_path: Saved filter appears in list.
        failure_path: Validation failure remains in save form with inline feedback.
        loading_or_processing_behavior: Save action is disabled while request is pending.
        feedback: Filter saved confirmation appears.
        recovery_path: User can edit name or cancel.
      - id: T-CANCEL-SAVE
        action_id: A-CANCEL-SAVE
        from_screen: S-SAVE-FILTER
        from_state: ST-SAVE-READY
        to_screen: S-REPORT
        to_state: ST-REPORT-READY
        trigger: cancel selected
        conditions: []
        success_path: Save form closes.
        failure_path: none
        feedback: Report remains unchanged.
        recovery_path: User can open save again.
      - id: T-APPLY-START
        action_id: A-APPLY-FILTER
        from_screen: S-SAVED-FILTERS
        from_state: ST-SAVED-FILTERS-LIST
        to_screen: S-SAVED-FILTERS
        to_state: ST-SAVED-FILTERS-LOADING
        trigger: apply selected
        conditions: [selected filter exists]
        success_path: Applying state appears.
        failure_path: If filter is unavailable, show recoverable error.
        feedback: Applying state appears.
        recovery_path: Retry or dismiss if request fails.
      - id: T-APPLY-SUCCESS
        action_id: A-APPLY-FILTER
        from_screen: S-SAVED-FILTERS
        from_state: ST-SAVED-FILTERS-LOADING
        to_screen: S-REPORT
        to_state: ST-REPORT-FILTER-APPLIED
        trigger: apply request succeeds
        conditions: [report refresh succeeds]
        success_path: Report shows selected saved filter criteria.
        failure_path: T-APPLY-FAILURE
        feedback: Active filter summary updates.
        recovery_path: User can reopen saved filters.
      - id: T-APPLY-FAILURE
        action_id: A-APPLY-FILTER
        from_screen: S-SAVED-FILTERS
        from_state: ST-SAVED-FILTERS-LOADING
        to_screen: S-SAVED-FILTERS
        to_state: ST-SAVED-FILTERS-ERROR
        trigger: apply request fails
        conditions: [report refresh fails or selected filter becomes unavailable]
        success_path: Previous report state is preserved and error recovery appears.
        failure_path: none
        feedback: Recoverable error explains that the report was not changed.
        recovery_path: A-RETRY-APPLY

    components:
      - id: C-SAVED-FILTERS-ENTRY
        type: entry_control
        purpose: Open saved filters.
        data_displayed: []
        user_actions: [A-OPEN-SAVED-FILTERS]
        validation_rules: []
      - id: C-SAVE-CURRENT-FILTERS
        type: entry_control
        purpose: Open save current filters flow.
        data_displayed: []
        user_actions: [A-OPEN-SAVE]
        validation_rules: []
      - id: C-FILTER-NAME
        type: text_input
        purpose: Capture saved filter name.
        data_displayed: [current entered name]
        user_actions: [A-SUBMIT-SAVE]
        validation_rules: [VR-NAME-REQUIRED, VR-DUPLICATE-NAME]
      - id: C-SAVED-FILTER-ROW
        type: list_row
        purpose: Display and apply one saved filter.
        data_displayed: [filter name, last updated time]
        user_actions: [A-APPLY-FILTER]
        validation_rules: []

    validation_rules:
      - id: VR-NAME-REQUIRED
        scope: field
        component_id: C-FILTER-NAME
        rule: Saved filter name is required.
        trigger: User submits save with an empty name.
        affected_actions: [A-SUBMIT-SAVE]
        failure_state: ST-SAVE-VALIDATION-ERROR
        feedback_pattern: FP-NAME-ERROR
        error_feedback: Explain that a name is required and keep the form open.
        recovery_behavior: User enters a valid name or cancels.
        related_acceptance_criteria: [AC-2]
      - id: VR-DUPLICATE-NAME
        scope: business
        component_id: C-FILTER-NAME
        rule: Duplicate names require overwrite confirmation or a different name.
        trigger: User submits a name that already exists for this report.
        affected_actions: [A-SUBMIT-SAVE]
        failure_state: ST-SAVE-VALIDATION-ERROR
        feedback_pattern: FP-NAME-ERROR
        error_feedback: Show duplicate-name decision path.
        recovery_behavior: User chooses overwrite if allowed or enters a different name.
        related_acceptance_criteria: [AC-2]

    business_rules:
      - id: BR-PERSONAL-SCOPE
        rule: Saved filters are personal and scoped to the current report.
        affected_flows: [F-SAVE-FILTER, F-APPLY-FILTER]
        affected_components: [C-SAVED-FILTER-ROW]
        related_acceptance_criteria: [AC-1, AC-3]
      - id: BR-PRESERVE-REPORT-ON-FAILURE
        rule: Failed apply must preserve the previous active report filter state.
        affected_flows: [F-APPLY-FILTER]
        affected_components: [C-SAVED-FILTER-ROW]
        related_acceptance_criteria: [AC-4]

    edge_cases:
      - id: EC-DUPLICATE-NAME
        scenario: User saves with a duplicate name.
        expected_behavior: Prompt overwrite confirmation if allowed or require a different name.
        affected_screen_or_flow: F-SAVE-FILTER
        recovery_behavior: User changes name, confirms overwrite, or cancels.
        status: open
        related_user_stories: [US-1]
        related_acceptance_criteria: [AC-2]
      - id: EC-APPLY-FAILED
        scenario: Selected saved filter cannot be applied.
        expected_behavior: Explain failure, preserve prior report state, and offer retry.
        affected_screen_or_flow: F-APPLY-FILTER
        recovery_behavior: A-RETRY-APPLY
        status: handled
        related_user_stories: [US-2]
        related_acceptance_criteria: [AC-4]

    feedback_patterns:
      - id: FP-NAME-ERROR
        event: validation_failed
        feedback_type: inline_error
        message_intent: Explain what must change while preserving typed value.
        affected_actions: [A-SUBMIT-SAVE]
        recovery_affordance: correct input or cancel
      - id: FP-APPLYING
        event: apply_in_progress
        feedback_type: loading_indicator
        message_intent: Show that the report is updating and conflicting actions are unavailable.
        affected_actions: [A-APPLY-FILTER]
        recovery_affordance:
      - id: FP-APPLY-FAILED
        event: apply_failed
        feedback_type: retry_affordance
        message_intent: Explain that the current report state was preserved and retry is available.
        affected_actions: [A-APPLY-FILTER, A-RETRY-APPLY]
        recovery_affordance: retry or dismiss

    open_decisions:
      - id: D-APPLY-SEMANTICS
        question: What are the final apply behavior semantics?
        affected_requirements: [PR-3]
        affected_flows: [F-APPLY-FILTER]
        affected_screens: [S-REPORT, S-SAVED-FILTERS]
        affected_states: [ST-REPORT-FILTER-APPLIED, ST-SAVED-FILTERS-LOADING, ST-SAVED-FILTERS-ERROR]
        affected_actions: [A-APPLY-FILTER, A-RETRY-APPLY]
        affected_acceptance_criteria: [AC-3, AC-4]
        options: [replace all current filters, merge partial filters, ask user each time]
        owner: Product
        needed_by: Before acceptance finalization
        blocks_interaction_design: true
        blocks_projection: true
        blocks_prototype_generation: true
        blocks_prototype_verification: true
        fallback_allowed: false
        recommended_resolver: Product owner with analytics or workflow evidence.
        blocked_artifacts: [downstream projection, prototype generation, prototype verification]
        impact_if_unresolved: Downstream projections cannot truthfully show final apply behavior.

  platform:
    target_surface: ipados_app
    adapter: apple_ipados
    implementation_claim: native_later
    device_bezel:
      type: ipad
      source: apple_design_resource
      resource_id: product-bezel/ipad
    input_methods: [touch, pointer, hardware_keyboard]
    platform_constraints: [safe_area_aware, dynamic_type_compatible, keyboard_accessible, pointer_compatible]
    adaptation_notes:
      - Use iPadOS as the primary review expression. macOS can reuse behavior IDs with a separate platform adapter later.
      - Platform bindings express how behavior is presented; they do not define destinations or product rules.
    convention_review:
      platform_convention_status: needed
      ux_quality_status: not_requested
      findings_to_resolve: [confirm saved filter list as popover versus sidebar in compact width]
      accepted_delta_links: []
    scene_presentations:
      - screen_id: S-REPORT
        state_id: ST-REPORT-READY
        container_primitive: NavigationSplitView
        navigation_context: report workspace
        regions:
          - region_id: report_results
            component_id:
            primitive: content_region
            placement: content
            emphasis: primary
          - region_id: saved_filter_actions
            component_id: C-SAVED-FILTERS-ENTRY
            primitive: ToolbarItem
            placement: toolbar
            emphasis: secondary
          - region_id: save_current_filter
            component_id: C-SAVE-CURRENT-FILTERS
            primitive: ToolbarItem
            placement: toolbar
            emphasis: primary
      - screen_id: S-SAVED-FILTERS
        state_id: ST-SAVED-FILTERS-LIST
        container_primitive: List
        navigation_context: popover_or_sidebar_panel
        regions:
          - region_id: saved_filter_rows
            component_id: C-SAVED-FILTER-ROW
            primitive: ListRow
            placement: content
            emphasis: primary
      - screen_id: S-SAVE-FILTER
        state_id: ST-SAVE-READY
        container_primitive: Form
        navigation_context: modal_sheet
        regions:
          - region_id: name_entry
            component_id: C-FILTER-NAME
            primitive: TextField
            placement: form_section
            emphasis: primary
    action_presentations:
      - action_id: A-OPEN-SAVED-FILTERS
        primitive: ToolbarItem
        placement: toolbar
        affordance: opens saved filter list
        emphasis: secondary
        input_methods: [touch, pointer, keyboard_shortcut_optional]
      - action_id: A-OPEN-SAVE
        primitive: ToolbarItem
        placement: toolbar
        affordance: opens save form
        emphasis: primary
        input_methods: [touch, pointer, keyboard_shortcut_optional]
      - action_id: A-SUBMIT-SAVE
        primitive: Button
        placement: sheet_primary_action
        affordance: confirms save
        emphasis: primary
        input_methods: [touch, pointer, return_key_optional]
      - action_id: A-CANCEL-SAVE
        primitive: Button
        placement: sheet_secondary_action
        affordance: cancels without saving
        emphasis: secondary
        input_methods: [touch, pointer, escape_key]
      - action_id: A-APPLY-FILTER
        primitive: row_tap_affordance
        placement: list_row
        affordance: applies selected saved filter
        emphasis: primary
        input_methods: [touch, pointer, keyboard]
      - action_id: A-RETRY-APPLY
        primitive: Button
        placement: inline_error_region
        affordance: retries apply request
        emphasis: primary
        input_methods: [touch, pointer, keyboard]
    transition_presentations:
      - transition_id: T-OPEN-SAVED-FILTERS
        primitive: popover_present
        animation_or_presentation_style: system_default
        platform_notes: Presentation only; destination remains defined by behavior transition.
      - transition_id: T-OPEN-SAVE
        primitive: sheet_present
        animation_or_presentation_style: system_default
        platform_notes: Sheet expresses the save form; behavior owns resulting screen/state.
      - transition_id: T-CANCEL-SAVE
        primitive: sheet_dismiss
        animation_or_presentation_style: system_default
        platform_notes: Dismissal presentation only.
      - transition_id: T-APPLY-START
        primitive: inline_state_change
        animation_or_presentation_style: progress feedback in current list
        platform_notes: No destination is defined here.
      - transition_id: T-APPLY-SUCCESS
        primitive: sheet_dismiss
        animation_or_presentation_style: return focus to report workspace
        platform_notes: Dismissal presentation only.
      - transition_id: T-APPLY-FAILURE
        primitive: inline_state_change
        animation_or_presentation_style: inline recoverable error
        platform_notes: Error presentation only.
    feedback_presentations:
      - feedback_id: FP-NAME-ERROR
        primitive: inline_field_error
        placement: below_text_field
      - feedback_id: FP-APPLYING
        primitive: progress_view
        placement: list_row_or_panel_header
      - feedback_id: FP-APPLY-FAILED
        primitive: inline_error_with_retry
        placement: saved_filter_panel
    validation_presentations:
      - validation_id: VR-NAME-REQUIRED
        primitive: inline_field_error
        placement: below_text_field
      - validation_id: VR-DUPLICATE-NAME
        primitive: confirmation_dialog
        placement: modal_decision_surface
    coverage_gaps:
      - behavior_id: D-APPLY-SEMANTICS
        behavior_type: open_decision
        reason: Apply semantics are not settled.
        blocks_projection: true
        acceptable_placeholder: Mark replace-vs-merge unresolved in prototype review.
    projection_notes:
      - Do not use exact margins, colors, typography sizes, or final component styling here.
      - Downstream HTML/Figma should use the iPad device bezel and Apple primitives as a plain review baseline.

  traceability:
    requirements: [PR-1, PR-2, PR-3, PR-4, PR-5]
    user_stories: [US-1, US-2]
    acceptance_criteria: [AC-1, AC-2, AC-3, AC-4]
    links:
      - model_id: F-SAVE-FILTER
        model_layer: behavior
        model_type: flow
        requirements: [PR-1, PR-2]
        user_stories: [US-1]
        acceptance_criteria: [AC-1, AC-2]
      - model_id: A-OPEN-SAVE
        model_layer: platform
        model_type: action_presentation
        requirements: [PR-1]
        user_stories: [US-1]
        acceptance_criteria: [AC-1]

  coverage_expectations:
    required_flows: [F-SAVE-FILTER, F-APPLY-FILTER]
    required_screens: [S-REPORT, S-SAVED-FILTERS, S-SAVE-FILTER]
    required_states_by_screen:
      - screen_id: S-SAVED-FILTERS
        states: [ST-SAVED-FILTERS-LIST, ST-SAVED-FILTERS-LOADING, ST-SAVED-FILTERS-ERROR]
      - screen_id: S-SAVE-FILTER
        states: [ST-SAVE-READY, ST-SAVE-VALIDATION-ERROR]
    required_interactions: [A-OPEN-SAVED-FILTERS, A-OPEN-SAVE, A-SUBMIT-SAVE, A-CANCEL-SAVE, A-APPLY-FILTER, A-RETRY-APPLY]
    required_platform_bindings: [S-REPORT, S-SAVED-FILTERS, S-SAVE-FILTER, A-OPEN-SAVE, A-APPLY-FILTER, T-OPEN-SAVE, T-APPLY-FAILURE]
    static_projection_allowed: []
    fake_allowed: [fixture saved filter data may be used if scope is labeled]
    out_of_scope: [team sharing, final visual design, production persistence]

  product_prototype_contract:
    purpose: Show the saved-filter workflow well enough for product review without turning the prototype into product truth.
    source_model_ids: [F-SAVE-FILTER, F-APPLY-FILTER, S-REPORT, S-SAVED-FILTERS, S-SAVE-FILTER, A-OPEN-SAVE, A-APPLY-FILTER, T-OPEN-SAVE, T-APPLY-FAILURE]
    required_screens: [report page, saved filters list, save filter form]
    required_flows: [save current filter set, apply saved filter]
    required_states: [default, loading, validation_error, error, success]
    required_click_paths:
      - Open saved filters from report page, choose filter, observe loading, reach success or failure recovery.
      - Open save form, submit missing name, recover, submit valid name.
    required_validation_and_feedback:
      - Name validation remains tied to the name field.
      - Apply failure preserves the previous active filter and offers retry.
    required_recovery_paths: [retry apply, cancel save, resolve name validation]
    required_permission_handoffs: []
    required_platform_expression: [apple_ipados, ipad device bezel, ToolbarItem, List, Form, sheet, popover, inline error]
    explicit_non_goals: [team sharing, final visual design, production persistence, renderer implementation]
    blocked_by_open_decisions: [D-APPLY-SEMANTICS]
    allowed_placeholders: [fixture filter names]
    coverage_verification_notes: [Every rendered interaction should map back to behavior IDs; platform presentation gaps must not invent behavior.]

  prototype_projection_controls:
    purpose: Let reviewers reach modeled loading, validation, and failure states without making debug controls product behavior.
    placement_rule: Put controls in reviewer chrome or a hidden review drawer, not inside the simulated app surface.
    source_of_truth_rule: Controls expose existing behavior IDs only and do not create new actions, transitions, or requirements.
    controls:
      - id: PC-APPLY-FAILURE
        exposes_behavior_ids: [ST-SAVED-FILTERS-ERROR, T-APPLY-FAILURE]
        control_type: reviewer_only_failure_injection
        real_trigger: apply_request_failed
        not_product_ui: true

  projection_targets:
    - target: html_product_prototype
      role: prototype_review
      source_model_ids: [behavior, platform, product_prototype_contract]
      target_constraints_notes: [Use Apple primitive projection as plain review baseline; do not add product behavior.]
      allowed_assumptions: [fixture saved-filter names, generated CSS bezel if official bezel is unavailable]
      prohibited_inventions: [do not change apply semantics, saved-filter scope, or recovery behavior]
      validation_checkpoints: [behavior ID coverage, platform binding coverage, gaps listed]

  projection_gaps:
    - id: PG-APPLY-SEMANTICS
      gap_type: open_decision
      affected_model_ids: [D-APPLY-SEMANTICS, F-APPLY-FILTER, A-APPLY-FILTER]
      owner: Product
      blocks_projection: true
      blocks_prototype_generation: true
      blocks_prototype_verification: true
      acceptable_placeholder: Mark apply semantics as replace-vs-merge unresolved.
      impact_if_unresolved: Downstream projection cannot truthfully show final apply behavior.

  downstream_handoff:
    prototype_projection_notes: [Use behavior as truth and platform as presentation binding.]
    figma_projection_notes: [Render Apple primitives plainly; visual polish is outside this model.]
    html_prototype_notes: [HTML artifact may use generated CSS device bezel if official bezel is unavailable.]
    prototype_review_notes: [Reviewers should check behavior coverage and platform expression separately.]
    projection_gap_links: [PG-APPLY-SEMANTICS]
    review_delta_links: []
```

## Why Platform Does Not Redefine Behavior

- `behavior.transitions` defines where `A-APPLY-FILTER` goes and what success
  or failure means.
- `platform.action_presentations` only says the action appears as a row tap or
  button.
- `platform.transition_presentations` only says the existing transition is
  visually presented as a sheet, popover, inline state change, or push.
- `platform` never defines `to_screen`, `to_state`, success path, failure path,
  product rule, or new user task.

## Platform Expression Summary

| Behavior ID | Binding | Platform primitive | Notes |
| --- | --- | --- | --- |
| S-REPORT / ST-REPORT-READY | scene presentation | NavigationSplitView, ToolbarItem | iPadOS review baseline; behavior remains in `behavior`. |
| S-SAVED-FILTERS / ST-SAVED-FILTERS-LIST | scene presentation | List in popover/sidebar panel | Presentation only. |
| S-SAVE-FILTER / ST-SAVE-READY | scene presentation | Form in sheet | Presentation only. |
| A-APPLY-FILTER | action presentation | row_tap_affordance | Does not define resulting screen/state. |
| T-APPLY-FAILURE | transition presentation | inline_state_change | Error behavior is defined in `behavior.transitions`. |

## Open Questions

| Question | Why it matters | Owner |
| --- | --- | --- |
| What are the final apply behavior semantics? | Determines whether downstream projections can show the apply flow as settled. | Product |
