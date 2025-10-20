# Firebase Cloud Messaging Test Script
# This script sends a test push notification to your device

# Configuration
$API_KEY = "AIzaSyA9L9u7hTM5ivm1mi8YnkQiJzvuquUECs0"
$FCM_TOKEN = "dEhLs3boSH-5PETlxUQr3N:APA91bGfT22m868ZB7B4sFrlGflE4x_lPCNhNcqlAFws8F1G77RvYUqMst9Y1LyCKEzUtEn-8v9kFwTcscNhhPh1pxpc-gxHWu9y4evXc8GOaif6-TQXYXg"

Write-Host "FIREBASE CLOUD MESSAGING TEST" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Headers
$headers = @{
    "Authorization" = "key=$API_KEY"
    "Content-Type" = "application/json"
}

# Test 1: Simple Notification
Write-Host "Test 1: Sending simple notification..." -ForegroundColor Yellow

$body1 = @{
    to = $FCM_TOKEN
    notification = @{
        title = "Van Full Alert!"
        body = "Van TEST1 is full and departing in 15 minutes."
    }
} | ConvertTo-Json

try {
    $response1 = Invoke-RestMethod -Uri "https://fcm.googleapis.com/fcm/send" -Method Post -Headers $headers -Body $body1
    Write-Host "SUCCESS! Message ID: $($response1.message_id)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 2: Notification with Data Payload
Write-Host "Test 2: Sending notification with data..." -ForegroundColor Yellow

$body2 = @{
    to = $FCM_TOKEN
    notification = @{
        title = "Your Van is Ready!"
        body = "Van TEST2 is now boarding. Please proceed to the terminal."
    }
    data = @{
        vanPlateNumber = "TEST2"
        bookingId = "test123"
        departureTime = "15"
        action = "VIEW_BOOKING"
    }
} | ConvertTo-Json

try {
    $response2 = Invoke-RestMethod -Uri "https://fcm.googleapis.com/fcm/send" -Method Post -Headers $headers -Body $body2
    Write-Host "SUCCESS! Message ID: $($response2.message_id)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 3: High Priority Notification
Write-Host "Test 3: Sending high priority notification..." -ForegroundColor Yellow

$body3 = @{
    to = $FCM_TOKEN
    priority = "high"
    notification = @{
        title = "URGENT: Van Departing!"
        body = "Your van is leaving NOW! Please hurry to the terminal."
        sound = "default"
    }
    data = @{
        priority = "urgent"
        vanPlateNumber = "TEST3"
    }
} | ConvertTo-Json

try {
    $response3 = Invoke-RestMethod -Uri "https://fcm.googleapis.com/fcm/send" -Method Post -Headers $headers -Body $body3
    Write-Host "SUCCESS! Message ID: $($response3.message_id)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "All tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Check your device for notifications!" -ForegroundColor Cyan
Write-Host "Check app console for logs starting with 'NotificationService:'" -ForegroundColor Cyan
Write-Host ""

# Instructions
Write-Host "TIPS:" -ForegroundColor Yellow
Write-Host "  - Keep the app running to see console logs" -ForegroundColor White
Write-Host "  - Test with app in foreground, background, and closed" -ForegroundColor White
Write-Host "  - Check notification tray for received messages" -ForegroundColor White
Write-Host "  - Update FCM_TOKEN if device token changes" -ForegroundColor White
