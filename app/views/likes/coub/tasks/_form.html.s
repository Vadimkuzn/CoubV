= form_for([:likes, @coub_task]) do |f|
  .form-group
    = f.label :title, "Название:",:class => 'col-lg-4 control-label'
    .col-lg-6
      = f.text_field :title, :class => 'form-control'

  .form-group
    = f.label :url, "Url:", :class => 'col-lg-4 control-label'
    .col-lg-6
      - locurl = f.text_field :url
      - if !:url.to_s.is_valid_url?
        - javascript_tag "alert('FAILED!')"
      = f.text_field :url, :disabled => !@coub_task.new_record?, :class => 'form-control', :required => true
      Ссылка вида https://coub.com/view/b9t15

  .form-group
    = f.label :members_count, "Сколько лайков накрутить:", :class => 'col-lg-4 control-label'
    .col-lg-6
      = f.number_field :members_count, :maxlength => "6", :class => 'form-control', :required => true
      Минимум 10

  .form-group
    = f.label :cost, "Вознаграждение за лайк:", :class => 'col-lg-4 control-label'
    .col-lg-6
      = f.number_field :cost, :maxlength => "2", :min => 1, :max => 15, :class => 'form-control', :required => true
      Минимум 1, Максимум 15

  .form-group
    = f.label :max_count, "Лайков будет списано:", :class => 'col-lg-4 control-label'
    .col-lg-6
      = f.text_field :max_count, :maxlength => "4", :disabled => true, :class => 'form-control'

  .actions
    = f.submit "Отправить задание", :class => 'btn btn-info'
