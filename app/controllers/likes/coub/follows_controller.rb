require 'v_coub_lib'
#--------------------------------------------------------------------------
class Likes::Coub::FollowsController < ApplicationController
  def index
   # список заданий для выполнения на подписки
   @coub_follow_tasks = CoubFollowTask.where(paused: false, suspended: false).where.not(user_id: current_user.id)
#   @coub_follow_tasks = CoubFollowTask.where(paused: false, suspended: false))
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
   vclib = VCoubLib.new(current_user)
   @coub_follow_task[:picture_path] = vclib.get_current_user_avatar()
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
