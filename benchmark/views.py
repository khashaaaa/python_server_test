from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.db import transaction
from .models import User
import json

@csrf_exempt
@require_http_methods(["POST"])
@transaction.atomic
def create_user(request):
    try:
        data = json.loads(request.body)
        print("Request Data:", data)
        email = data['email'].lower()
        user = User.objects.create(
            name=data['name'].strip(),
            email=email
        )
        return JsonResponse({
            'id': user.id,
            'name': user.name,
            'email': user.email
        }, status=201)
    except KeyError:
        return JsonResponse({'error': 'Missing required fields'}, status=400)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

@require_http_methods(["GET"])
def get_users(request):
    try:
        users = User.objects.values('id', 'name', 'email').order_by('id')
        return JsonResponse(list(users), safe=False)
    except ValueError:
        return JsonResponse({'error': 'Invalid page number'}, status=400)

@csrf_exempt
@require_http_methods(["PUT"])
@transaction.atomic
def update_user(request, user_id):
    try:
        data = json.loads(request.body)
        user = User.objects.get(id=user_id)
        
        if 'name' in data:
            user.name = data['name'].strip()
        
        if 'email' in data:
            user.email = data['email'].lower()
        
        user.save()

        return JsonResponse({
            'id': user.id,
            'name': user.name,
            'email': user.email
        })
    except User.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

@csrf_exempt
@require_http_methods(["DELETE"])
@transaction.atomic
def delete_user(request, user_id):
    try:
        user = User.objects.get(id=user_id)
        user.delete()
        
        return JsonResponse({'message': 'Deleted'})
    except User.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)
