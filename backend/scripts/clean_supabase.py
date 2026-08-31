import os
import sys
import urllib.request
import json

BASE_URL = os.environ.get('SUPABASE_URL', 'https://wuzrwqqqidrnziphamzr.supabase.co')
SECRET_KEY = os.environ.get('SUPABASE_SERVICE_ROLE_KEY') or (sys.argv[1] if len(sys.argv) > 1 else None)

if not SECRET_KEY:
    print('Usage: python clean_supabase.py <SUPABASE_SERVICE_ROLE_KEY>')
    print('Or set SUPABASE_SERVICE_ROLE_KEY environment variable.')
    sys.exit(1)

headers = {
    'apikey': SECRET_KEY,
    'Authorization': f'Bearer {SECRET_KEY}',
    'User-Agent': 'Node/18',
    'Content-Type': 'application/json'
}

tables = [
    'sale_items',
    'sales',
    'expenses',
    'products',
    'categories',
    'business_calendar_days',
    'onboarding_checklist_items',
    'password_resets',
    'business_profiles'
]

print('=== 1. Deleting Table Data ===')
for table in tables:
    url = f'{BASE_URL}/rest/v1/{table}?id=not.is.null'
    req = urllib.request.Request(url, headers=headers, method='DELETE')
    try:
        with urllib.request.urlopen(req) as resp:
            print(f'Cleared table: {table} (status: {resp.status})')
    except urllib.error.HTTPError as e:
        err_body = e.read().decode()
        print(f'Table {table}: HTTP {e.code} - {err_body}')
    except Exception as e:
        print(f'Table {table}: {e}')

print('\n=== 2. Deleting Auth Users ===')
try:
    req = urllib.request.Request(f'{BASE_URL}/auth/v1/admin/users', headers=headers)
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode())
        users = data.get('users', [])
        print(f'Found {len(users)} user(s)')
        for u in users:
            uid = u['id']
            email = u.get('email', '')
            del_req = urllib.request.Request(f'{BASE_URL}/auth/v1/admin/users/{uid}', headers=headers, method='DELETE')
            with urllib.request.urlopen(del_req) as del_resp:
                print(f'Deleted user: {email} (ID: {uid})')
except urllib.error.HTTPError as e:
    print(f'Auth error: HTTP {e.code} - {e.read().decode()}')
except Exception as e:
    print(f'Auth error: {e}')

print('\n=== 3. Deleting Storage Objects ===')
try:
    list_req = urllib.request.Request(
        f'{BASE_URL}/storage/v1/object/list/product-images',
        headers=headers,
        data=json.dumps({'prefix': '', 'limit': 100, 'offset': 0}).encode('utf-8')
    )
    with urllib.request.urlopen(list_req) as resp:
        files = json.loads(resp.read().decode())
        print(f'Found {len(files)} file(s) in product-images')
        for f in files:
            fname = f['name']
            del_req = urllib.request.Request(
                f'{BASE_URL}/storage/v1/object/product-images',
                headers=headers,
                data=json.dumps({'prefixes': [fname]}).encode('utf-8'),
                method='DELETE'
            )
            with urllib.request.urlopen(del_req) as del_resp:
                print(f'Deleted storage file: {fname}')
except urllib.error.HTTPError as e:
    print(f'Storage error: HTTP {e.code} - {e.read().decode()}')
except Exception as e:
    print(f'Storage error: {e}')

print('\n=== Deletion Complete! ===')
