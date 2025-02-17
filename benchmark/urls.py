from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.get_users, name='get_users'),
    path('create/', views.create_user, name='create_user'),
    path('<int:user_id>/', views.get_user, name='get_user'),
    path('<int:user_id>/update/', views.update_user, name='update_user'),
    path('<int:user_id>/delete/', views.delete_user, name='delete_user'),
]