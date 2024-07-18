module CommonMethods
  # factory methods

  def make_workflow(ctx, states)
    payload = {"StartAt" => states.keys.first, "States" => states}
    Floe::Workflow.new(payload, ctx)
  end
end
