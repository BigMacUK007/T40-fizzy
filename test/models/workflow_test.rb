require "test_helper"

class WorkflowTest < ActiveSupport::TestCase
  test "create with default stages" do
    workflow = Workflow.create name: "My New Workflow"
    assert_equal Workflow::DEFAULT_STAGES.sort, workflow.stages.collect(&:name).sort
  end
end
