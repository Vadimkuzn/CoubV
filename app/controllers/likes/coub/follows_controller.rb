require 'v_coub_lib'
#--------------------------------------------------------------------------
class Likes::Coub::FollowsController < ApplicationController
  def index
# список заданий для выполнения на подписки
#   @coub_follow_tasks = CoubFollowTask.where(paused: false, suspended: false, finished: false).where.not(user_id: current_user.id).order(cost: :desc).first(20)
#CHANGE!!!
   @coub_follow_tasks = CoubFollowTask.where(paused: false, suspended: false, finished: false).order(cost: :desc).first(20)
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

   vclib = VCoubLib.new(current_user)

   @coub_follow_task = current_user.coub_follow_tasks.build(task_params)

   etask = CoubTask.get_existing(vclib.channel_id_by_url(@coub_follow_task.url), @coub_follow_task.user_id, @coub_follow_task.type, false, false)

   if etask
    @coub_follow_task = etask
    if @coub_follow_task.update(task_params)
     redirect_to likes_coub_tasks_path
    else
     render 'edit'
    end
    return
   end

   @coub_follow_task[:picture_path] = vclib.get_avatar(@coub_follow_task[:url])
   if @coub_follow_task.save
    flash[:success] = "Задание успешно создано!"
#     redirect_to likes_coub_follow_path(@coub_follow_task)
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
