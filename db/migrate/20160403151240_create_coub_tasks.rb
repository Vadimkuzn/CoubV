class CreateCoubTasks < ActiveRecord::Migration
  def change
    create_table :coub_tasks do |t|
     t.integer   "user_id",       null:    false               # кто поставил задание. на данном этапе забей на это поле
     t.string    "title",         limit:   255                 # название задания, необязательное, больше для юзера
     t.string    "ctype",         limit:   255, null: false    # тип задания(сейчас это будет только 1 тип: CbLikeTask - накрутка лайков к записи)
     t.string    "url",           limit:   255, null: false    # адрес, куда будут накручиваться лайки. например: https://coub.com/view/bfrkm
     t.integer   "cost",          null:    false               # стоимость в баллах за одно выполнение задания.
     t.string    "item_id",       limit:   255, null: false    # внутренний идентификатор записи на сайте coub. их внутренний id
     t.string    "shortcode",     limit:   255                 # короткое имя записи, для ссылки https://coub.com/view/bfrkm это будет bfrkm
     t.boolean   "deleted",       default: false, null: false  # удалено задание или нет
     t.boolean   "paused",        default: false, null: false  # задание на паузе или нет(юзер может сам ставить и снимать с паузы)
     t.boolean   "suspended",     default: false, null: false  # задание заморожено или нет
     t.boolean   "verified",      default: false, null: false  # на будущее
     t.integer   "current_count", null:    false               # количество баллов на балансе аккаунта
     t.integer   "max_count",     null:    false               #
     t.integer   "members_count", null:    false               #
     t.string    "picture_path",  limit:   255                 # url картинки, которая будет отображаться при выполнении задания
     t.boolean   "finished",      default: false, null: false  # задание завершено(выполнено) или нет
     t.datetime  "created_at",    null:    false
     t.datetime  "updated_at",    null:    false
     t.timestamps null: false

     t.timestamps null: false
    end
  end
end
