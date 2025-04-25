class WorkflowsController < ApplicationController
  before_action :set_workflow, only: %i[ show edit update destroy ]

  def index
    @workflows = Workflow.all
  end

  def new
    @workflow = Workflow.new
  end

  def create
    @workflow = Workflow.create! workflow_params
    redirect_to workflows_path
  end

  def show
  end

  def edit
  end

  def update
    @workflow.update! workflow_params
    redirect_to @workflow
  end

  def destroy
    @workflow.destroy
    redirect_to workflows_path
  end

  private
    def set_workflow
      @workflow = Workflow.find params[:id]
    end

    def workflow_params
      params.expect workflow: :name
    end
end
