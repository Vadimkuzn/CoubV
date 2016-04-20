class Likes::Coub::TasksController < ApplicationController
#--------------------------------------------------------------------------
  def index
   if current_user
    @coub_tasks = current_user.coub_tasks
   end
  end
#--------------------------------------------------------------------------
  def show
   @coub_task = CoubTask.find(params[:id])
  end
#--------------------------------------------------------------------------
  def new
   @coub_task = CoubTask.new
  end
#--------------------------------------------------------------------------
  def edit
   @coub_task = CoubTask.find(params[:id])
  end
#--------------------------------------------------------------------------
  def create
   @coub_task = current_user.coub_tasks.build(task_params)
   @coub_task[:type] = :CbLikeTask
   @coub_task[:picture_path] = "fff"     #temporary
   if @coub_task.save
    redirect_to [:likes, @coub_task]
   else
    render 'new'
   end
  end
#--------------------------------------------------------------------------
  def update
   @coub_task = CoubTask.find(params[:id])
   if @coub_task.update(task_params)
    redirect_to [:likes, @coub_task]
   else
    render 'edit'
   end
  end
#--------------------------------------------------------------------------
  def destroy
   @coub_task = CoubTask.find(params[:id])
   @coub_task.deleted = true
   @coub_task.save!
   redirect_to likes_coub_tasks_path
  end
#--------------------------------------------------------------------------
  def delete_all
   current_user.coub_tasks.each do |t|
    t.deleted = true
    t.save!
   end
   redirect_to likes_coub_tasks_path
  end
#--------------------------------------------------------------------------
  def pause
   @coub_task = CoubTask.find(params[:task_id])
   @coub_task.paused ? @coub_task.paused = false : @coub_task.paused = true
   @coub_task.save!
   redirect_to likes_coub_tasks_path
  end
#--------------------------------------------------------------------------
private
  def task_params
   params.require(:coub_task).permit(:user_id, :title, :type, :url, :cost, :item_id, :shortcode, :deleted, :paused, :suspended, :verified, :current_count, :max_count, :members_count, :picture_path, :finished, :created_at, :updated_at)
  end
#--------------------------------------------------------------------------
end
