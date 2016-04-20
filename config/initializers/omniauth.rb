Rails.application.config.middleware.use OmniAuth::Builder do
 provider :coub, "8d210ce217dcfa2ead2e1a7539ca83634d80eb8237753016a23956cac715b35a", "74bba6156a7d01ca4f66892d9a7b45d2ee5d30e86f931cadc963b611c7a9389b", scope: "logged_in,create,like,recoub,follow,channel_edit"
end
