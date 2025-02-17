from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.paginator import Paginator
from django.db import transaction
from django.core.cache import cache
from .models import User
import json

def rate_check(client_ip):
    key = f'rate:{client_ip}'
    if cache.get(key, 0) >= 1000:
        return False
    cache.get_or_set(key, 0, 60)
    cache.incr(key)
    return True

@csrf_exempt
@transaction.atomic
def create_user(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
        
    if not rate_check(request.META.get('REMOTE_ADDR')):
        return JsonResponse({'error': 'Too many requests'}, status=429)

    try:
        data = json.loads(request.body)
        if User.objects.filter(email=data['email']).exists():
            return JsonResponse({'error': 'Email exists'}, status=400)
            
        user = User.objects.create(
            name=data['name'].strip(),
            email=data['email'].lower()
        )
        return JsonResponse({
            'id': user.id,
            'name': user.name,
            'email': user.email
        }, status=201)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)

def get_users(request):
    if request.method != 'GET':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    try:
        page = int(request.GET.get('page', 1))
        size = min(int(request.GET.get('size', 50)), 100)
        
        users = User.objects.all().order_by('id')
        paginator = Paginator(users, size)
        users_page = paginator.get_page(page)
        
        return JsonResponse(list(users_page.object_list.values()), safe=False)
    except ValueError:
        return JsonResponse({'error': 'Invalid pagination parameters'}, status=400)

def get_user(request, user_id):
    if request.method != 'GET':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    try:
        user = User.objects.get(id=user_id)
        return JsonResponse({
            'id': user.id,
            'name': user.name,
            'email': user.email
        })
    except User.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)

@csrf_exempt
@transaction.atomic
def update_user(request, user_id):
    if request.method != 'PUT':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    try:
        user = User.objects.get(id=user_id)
        data = json.loads(request.body)
        
        if 'name' in data:
            user.name = data['name'].strip()
        if 'email' in data:
            new_email = data['email'].lower()
            if new_email != user.email and User.objects.filter(email=new_email).exists():
                return JsonResponse({'error': 'Email exists'}, status=400)
            user.email = new_email
            
        user.save()
        return JsonResponse({
            'id': user.id,
            'name': user.name,
            'email': user.email
        })
    except User.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)

@csrf_exempt
@transaction.atomic
def delete_user(request, user_id):
    if request.method != 'DELETE':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    try:
        user = User.objects.get(id=user_id)
        user.delete()
        return JsonResponse({'message': 'Deleted'})
    except User.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)