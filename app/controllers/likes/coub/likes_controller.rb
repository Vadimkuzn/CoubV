require 'my_coub_lib'

class Likes::Coub::LikesController < ApplicationController
#--------------------------------------------------------------------------
  def index
  end
#--------------------------------------------------------------------------
  def new
    @coub_like_task = CoubLikeTask.new
  end
#--------------------------------------------------------------------------
  def edit
  end
#--------------------------------------------------------------------------
  def create
    #@coub_task = current_user.coub_like_tasks.build(task_params)
    @coub_like_task = current_user.coub_like_tasks.build(task_params)

#render plain: params[:coub_task].inspect
#render plain: @coub_task.inspect
    #@coub_task[:type] = coub_like_task[:type]     #temporary
    @coub_like_task[:picture_path] = "fff"     #temporary

    if @coub_like_task.save
#render plain: @coub_task.inspect
#    result = MyCoubLib.new.does_like?(current_user)
#    render plain: result.inspect

# does_like?(item_id, access_token)
      redirect_to likes_coub_tasks_path
    else
      render 'new'
    end
  end
#--------------------------------------------------------------------------
  def update
  end
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
private
  def task_params
   params.require(:coub_like_task).permit(:user_id, :title, :type, :url, :cost, :item_id, :shortcode, :deleted, :paused, :suspended, :verified, :current_count, :max_count, :members_count, :picture_path, :finished)
  end
#--------------------------------------------------------------------------
end
