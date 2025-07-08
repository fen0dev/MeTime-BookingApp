// Services data (prices in DKK)
const services = [
    { id: 1, name: "Quick Fix Polish", duration: 15, price: 150, emoji: "💅", description: "Quick polish refresh" },
    { id: 2, name: "Gel Manicure", duration: 45, price: 450, emoji: "✨", description: "Long-lasting gel manicure" },
    { id: 3, name: "Spa Pedicure", duration: 60, price: 550, emoji: "🦶", description: "Relaxing spa pedicure" },
    { id: 4, name: "Nail Art", duration: 30, price: 250, emoji: "🎨", description: "Creative nail designs" },
    { id: 5, name: "Polish Change", duration: 20, price: 200, emoji: "💖", description: "Quick polish change" },
    { id: 6, name: "Gel Removal", duration: 15, price: 100, emoji: "🧼", description: "Safe gel removal" }
];

// State
let currentStep = 1;
let scheduleData = null;
let selectedServices = [];
let selectedTimeSlot = null;
let customerData = { name: '', phone: '+45', email: '', notes: '', smsOptIn: false };

// Get schedule ID from URL
const urlParams = new URLSearchParams(window.location.search);
const scheduleId = urlParams.get('id') || window.location.pathname.split('/').pop();

// Utility Functions
function showNotification(message, type = 'success') {
    const notification = document.getElementById('notification');
    const messageEl = document.getElementById('notificationMessage');
    
    messageEl.textContent = message;
    notification.className = `notification ${type}`;
    notification.style.display = 'flex';
    
    setTimeout(() => {
        notification.style.display = 'none';
    }, 5000);
}

function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

function validateDanishPhone(phone) {
    const cleaned = phone.replace(/\s/g, '');
    const re = /^\+45[0-9]{8}$/;
    return re.test(cleaned);
}

// Load schedule data
async function loadSchedule() {
    try {
        if (!scheduleId) {
            showError('Invalid booking link');
            return;
        }
        
        const doc = await db.collection('schedules').doc(scheduleId).get();
        
        if (!doc.exists) {
            showError('Invalid booking link');
            return;
        }
        
        scheduleData = doc.data();
        scheduleData.id = doc.id;
        
        // Display date
        const date = new Date(scheduleData.date.seconds * 1000);
        document.getElementById('dateDisplay').textContent = 
            date.toLocaleDateString('en-US', { 
                weekday: 'long', 
                year: 'numeric', 
                month: 'long', 
                day: 'numeric' 
            });
        
        showStep(1);
    } catch (error) {
        console.error('Error loading schedule:', error);
        showError('Error loading booking information');
    }
}

function showError(message) {
    document.getElementById('content').innerHTML = 
        `<div class="error">${message}</div>`;
}

function showStep(step) {
    currentStep = step;
    updateProgress();
    
    const content = document.getElementById('content');
    
    switch(step) {
        case 1:
            showServicesStep();
            break;
        case 2:
            showTimeStep();
            break;
        case 3:
            showDetailsStep();
            break;
    }
}

function updateProgress() {
    for (let i = 1; i <= 3; i++) {
        const circle = document.getElementById(`progress${i}`);
        if (i < currentStep) {
            circle.classList.add('completed');
            circle.classList.remove('active');
        } else if (i === currentStep) {
            circle.classList.add('active');
            circle.classList.remove('completed');
        } else {
            circle.classList.remove('active', 'completed');
        }
    }
}

function showServicesStep() {
    let html = `
        <div class="card">
            <h2>Select Your Services</h2>
            <div style="margin-top: 20px;">
    `;
    
    services.forEach(service => {
        const isSelected = selectedServices.some(s => s.id === service.id);
        html += `
            <div class="service-item ${isSelected ? 'selected' : ''}" 
                 onclick="toggleService(${service.id})">
                <span class="service-emoji">${service.emoji}</span>
                <div class="service-details">
                    <div class="service-name">${service.name}</div>
                    <div style="font-size: 0.85em; color: var(--text-secondary); margin: 2px 0;">
                        ${service.description}
                    </div>
                    <div class="service-info">
                        <span>⏱ ${service.duration} min</span>
                        <span>💵 ${service.price} kr</span>
                    </div>
                </div>
                <div class="checkbox ${isSelected ? 'checked' : ''}"></div>
            </div>
        `;
    });
    
    html += `</div></div>`;
    
    if (selectedServices.length > 0) {
        const totalDuration = selectedServices.reduce((sum, s) => sum + s.duration, 0);
        const totalPrice = selectedServices.reduce((sum, s) => sum + s.price, 0);
        
        html += `
            <div class="card summary">
                <div class="summary-row">
                    <span>Total Duration:</span>
                    <span>${totalDuration} minutes</span>
                </div>
                <div class="summary-row total">
                    <span>Total Price:</span>
                    <span>${totalPrice} kr</span>
                </div>
            </div>
        `;
    }
    
    html += `
        <div class="navigation">
            <button class="btn btn-primary" 
                    onclick="showStep(2)"
                    ${selectedServices.length === 0 ? 'disabled' : ''}>
                Next <span>→</span>
            </button>
        </div>
    `;
    
    document.getElementById('content').innerHTML = html;
}

function toggleService(serviceId) {
    const service = services.find(s => s.id === serviceId);
    const index = selectedServices.findIndex(s => s.id === serviceId);
    
    if (index >= 0) {
        selectedServices.splice(index, 1);
    } else {
        selectedServices.push(service);
    }
    
    showServicesStep();
}

function showTimeStep() {
    const availableSlots = getAvailableSlots();
    
    let html = `
        <div class="card">
            <h2>Select Your Time</h2>
            <div class="time-grid">
    `;
    
    if (availableSlots.length === 0) {
        html += `<p style="grid-column: 1/-1; text-align: center; color: var(--text-secondary);">
                 No available time slots for the selected services.</p>`;
    } else {
        availableSlots.forEach(slot => {
            const isSelected = selectedTimeSlot?.id === slot.id;
            html += `
                <div class="time-slot ${isSelected ? 'selected' : ''}" 
                     onclick="selectTimeSlot('${slot.id}')">
                    ${formatTime(slot.startTime)}
                </div>
            `;
        });
    }
    
    html += `
            </div>
        </div>
        <div class="navigation">
            <button class="btn btn-secondary" onclick="showStep(1)">
                <span>←</span> Back
            </button>
            <button class="btn btn-primary" 
                    onclick="showStep(3)"
                    ${!selectedTimeSlot ? 'disabled' : ''}>
                Next <span>→</span>
            </button>
        </div>
    `;
    
    document.getElementById('content').innerHTML = html;
}

function getAvailableSlots() {
    const totalDuration = selectedServices.reduce((sum, s) => sum + s.duration, 0);
    const closingTime = new Date(scheduleData.date.seconds * 1000);
    closingTime.setHours(22, 0, 0, 0);
    
    return scheduleData.timeSlots.filter(slot => {
        if (slot.isBooked) return false;
        
        const slotTime = new Date(slot.startTime.seconds * 1000);
        const endTime = new Date(slotTime.getTime() + totalDuration * 60000);
        
        if (endTime > closingTime) return false;
        
        // Check for conflicts with other bookings
        const slotIndex = scheduleData.timeSlots.findIndex(s => s.id === slot.id);
        for (let i = slotIndex; i < scheduleData.timeSlots.length; i++) {
            const checkSlot = scheduleData.timeSlots[i];
            const checkTime = new Date(checkSlot.startTime.seconds * 1000);
            
            if (checkSlot.isBooked && checkTime < endTime) {
                return false;
            }
            if (checkTime >= endTime) break;
        }
        
        return true;
    });
}

function selectTimeSlot(slotId) {
    selectedTimeSlot = scheduleData.timeSlots.find(s => s.id === slotId);
    showTimeStep();
}

function formatTime(timestamp) {
    const date = new Date(timestamp.seconds * 1000);
    return date.toLocaleTimeString('en-US', { 
        hour: 'numeric', 
        minute: '2-digit',
        hour12: true 
    });
}

function showDetailsStep() {
    const totalPrice = selectedServices.reduce((sum, s) => sum + s.price, 0);
    const totalDuration = selectedServices.reduce((sum, s) => sum + s.duration, 0);
    const startTime = new Date(selectedTimeSlot.startTime.seconds * 1000);
    const endTime = new Date(startTime.getTime() + totalDuration * 60000);
    
    let html = `
        <div class="card">
            <h2>Your Information</h2>
            <div class="form-group" id="nameGroup">
                <label>Your Name *</label>
                <input type="text" id="customerName" value="${customerData.name}" 
                       placeholder="Enter your name" onblur="validateField('name')">
                <div class="error-message" id="nameError"></div>
            </div>
            <div class="form-group" id="phoneGroup">
                <label>Phone Number * (Danish)</label>
                <input type="tel" id="customerPhone" value="${customerData.phone}" 
                       placeholder="+45XXXXXXXX" onblur="validateField('phone')"
                       oninput="handlePhoneInput(this)" maxlength="11">
                <div style="font-size: 0.85em; color: var(--text-secondary); margin-top: 5px;">
                    Danish phone number format: +45 followed by 8 digits
                </div>
                <div class="error-message" id="phoneError"></div>
            </div>
            <div class="form-group" id="emailGroup">
                <label>Email Address (Optional)</label>
                <input type="email" id="customerEmail" value="${customerData.email}" 
                       placeholder="your@email.com" onblur="validateField('email')">
                <div style="font-size: 0.85em; color: var(--text-secondary); margin-top: 5px;">
                    We'll send booking confirmation to the salon owner
                </div>
                <div class="error-message" id="emailError"></div>
            </div>
            <div class="form-group">
                <label>Special Notes (Optional)</label>
                <textarea id="customerNotes" placeholder="Any special requests or notes...">${customerData.notes}</textarea>
            </div>
        </div>
        
        <div class="card summary">
            <h3>Booking Summary</h3>
            <div style="margin-top: 15px;">
                <div class="summary-row">
                    <span>📅 Date:</span>
                    <span>${startTime.toLocaleDateString()}</span>
                </div>
                <div class="summary-row">
                    <span>⏰ Time:</span>
                    <span>${formatTime(selectedTimeSlot.startTime)} - ${formatTime({seconds: endTime.getTime() / 1000})}</span>
                </div>
                <div class="summary-row">
                    <span>✨ Services:</span>
                    <span>${selectedServices.map(s => s.name).join(', ')}</span>
                </div>
                <div class="summary-row total">
                    <span>Total:</span>
                    <span>${totalPrice} kr</span>
                </div>
            </div>
        </div>
        
        <div class="navigation">
            <button class="btn btn-secondary" onclick="showStep(2)">
                <span>←</span> Back
            </button>
            <button class="btn btn-primary" onclick="confirmBooking()">
                <span>✓</span> Book Appointment
            </button>
        </div>
    `;
    
    document.getElementById('content').innerHTML = html;
}

function validateField(field) {
    const groups = {
        name: 'nameGroup',
        phone: 'phoneGroup',
        email: 'emailGroup'
    };
    
    const errors = {
        name: 'nameError',
        phone: 'phoneError',
        email: 'emailError'
    };
    
    const values = {
        name: document.getElementById('customerName').value.trim(),
        phone: document.getElementById('customerPhone').value.trim(),
        email: document.getElementById('customerEmail').value.trim()
    };
    
    const group = document.getElementById(groups[field]);
    const errorEl = document.getElementById(errors[field]);
    
    let isValid = true;
    let errorMessage = '';
    
    switch(field) {
        case 'name':
            if (!values.name) {
                isValid = false;
                errorMessage = 'Name is required';
            }
            break;
        case 'phone':
            if (!values.phone) {
                isValid = false;
                errorMessage = 'Phone number is required';
            } else if (!validateDanishPhone(values.phone)) {
                isValid = false;
                errorMessage = 'Please enter a valid Danish phone number (+45XXXXXXXX)';
            }
            break;
        case 'email':
            if (values.email && !validateEmail(values.email)) {
                isValid = false;
                errorMessage = 'Please enter a valid email address';
            }
            break;
    }
    
    if (isValid) {
        group.classList.remove('error');
        errorEl.textContent = '';
    } else {
        group.classList.add('error');
        errorEl.textContent = errorMessage;
    }
    
    return isValid;
}

async function confirmBooking() {
    const name = document.getElementById('customerName').value.trim();
    const phone = document.getElementById('customerPhone').value.trim();
    const email = document.getElementById('customerEmail').value.trim();
    const notes = document.getElementById('customerNotes').value.trim();
    const smsOptIn = false;
    
    // Validate all fields
    const isNameValid = validateField('name');
    const isPhoneValid = validateField('phone');
    const isEmailValid = validateField('email');
    
    if (!isNameValid || !isPhoneValid || !isEmailValid) {
        showNotification('Please fill in all required fields correctly', 'error');
        return;
    }
    
    customerData = { name, phone, email, notes, smsOptIn };
    
    // Show loading state
    const button = event.target;
    button.disabled = true;
    button.innerHTML = '<span class="spinner" style="width: 20px; height: 20px; border-width: 3px;"></span> Booking...';
    
    try {
        // Update the time slot
        const slotIndex = scheduleData.timeSlots.findIndex(s => s.id === selectedTimeSlot.id);
        scheduleData.timeSlots[slotIndex].isBooked = true;
        scheduleData.timeSlots[slotIndex].customerName = name;
        scheduleData.timeSlots[slotIndex].customerPhone = phone;
        scheduleData.timeSlots[slotIndex].customerEmail = email;
        scheduleData.timeSlots[slotIndex].notes = notes;
        scheduleData.timeSlots[slotIndex].smsOptIn = smsOptIn;
        scheduleData.timeSlots[slotIndex].services = selectedServices;
        scheduleData.timeSlots[slotIndex].bookingDate = new Date();
        
        // Mark subsequent slots as booked
        const totalDuration = selectedServices.reduce((sum, s) => sum + s.duration, 0);
        const slotsNeeded = Math.ceil(totalDuration / 15) - 1;
        
        for (let i = 1; i <= slotsNeeded; i++) {
            const nextIndex = slotIndex + i;
            if (nextIndex < scheduleData.timeSlots.length) {
                scheduleData.timeSlots[nextIndex].isBooked = true;
            }
        }
        
        // Update Firebase
        await db.collection('schedules').doc(scheduleId).update({
            timeSlots: scheduleData.timeSlots
        });
        
        // Update confirmation message
        document.getElementById('confirmationMessage').textContent = 
            'Your appointment has been confirmed! The salon will contact you if needed.';
        
        // Show success
        document.getElementById('successModal').style.display = 'flex';
    } catch (error) {
        console.error('Error booking appointment:', error);
        showNotification('Error booking appointment. Please try again.', 'error');
        
        // Reset button
        button.disabled = false;
        button.innerHTML = '<span>✓</span> Book Appointment';
    }
}

function closeSuccessModal() {
    document.getElementById('successModal').style.display = 'none';
    // Redirect to a thank you page or home
    window.location.href = '/';
}

function handlePhoneInput(input) {
    let value = input.value;
    
    // Ensure it starts with +45
    if (!value.startsWith('+45')) {
        value = '+45';
    }
    
    // Remove any non-digit characters after +45
    const digits = value.substring(3).replace(/\D/g, '');
    
    // Limit to 8 digits after +45
    if (digits.length > 8) {
        value = '+45' + digits.substring(0, 8);
    } else {
        value = '+45' + digits;
    }
    
    input.value = value;
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    loadSchedule();
});