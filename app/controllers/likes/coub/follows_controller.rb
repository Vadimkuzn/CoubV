require 'my_coub_lib'
#--------------------------------------------------------------------------
class Likes::Coub::FollowsController < ApplicationController
  def index
   # список заданий для выполнения на подписки
   if current_user
    @coub_tasks = current_user.coub_tasks
   end
  end
#--------------------------------------------------------------------------
  def new
   @coub_follow_task = CoubFollowTask.new
  end
#--------------------------------------------------------------------------
  def edit
   @coub_follow_task = CoubFollowTask.find(params[:id])
  end
#--------------------------------------------------------------------------
  def show
   @coub_follow_task = CoubFollowTask.find(params[:id])
  end
#--------------------------------------------------------------------------
  def create
    @coub_follow_task = current_user.coub_follow_tasks.build(task_params)
    @coub_follow_task[:picture_path] = "fff"     #temporary

    if @coub_follow_task.save
      redirect_to likes_coub_tasks_path
    else
      render 'new'
    end
  end
#--------------------------------------------------------------------------
  def update
   @coub_follow_task = CoubFollowTask.find(params[:id])
   if @coub_follow_task.update(task_params)
#    redirect_to [:follows, @coub_follow_task]
    redirect_to likes_coub_tasks_path
   else
    render 'edit'
   end
  end
#--------------------------------------------------------------------------

  private
  def task_params
   params.require(:coub_follow_task).permit(:user_id, :title, :type, :url, :cost, :item_id, :shortcode, :deleted, :paused, :suspended, :verified, :current_count, :max_count, :members_count, :picture_path, :finished)
  end
#--------------------------------------------------------------------------
end
