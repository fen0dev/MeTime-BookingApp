const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');

admin.initializeApp();

// Initialize Twilio (you'll need to set these in Firebase config)
const accountSid = functions.config().twilio.account_sid;
const authToken = functions.config().twilio.auth_token;
const twilioPhoneNumber = functions.config().twilio.phone_number;
const client = twilio(accountSid, authToken);

exports.sendBookingConfirmation = functions.firestore
    .document('schedules/{scheduleId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const previousData = change.before.data();
        
        // Find newly booked slots
        const newBookings = [];
        
        newData.timeSlots.forEach((slot, index) => {
            const wasBooked = previousData.timeSlots[index]?.isBooked || false;
            const isNowBooked = slot.isBooked && slot.customerName;
            
            if (!wasBooked && isNowBooked) {
                newBookings.push(slot);
            }
        });
        
        // Send SMS for each new booking
        for (const booking of newBookings) {
            if (booking.customerPhone && booking.customerName) {
                await sendSMS(booking, newData.date);
            }
        }
        
        return null;
    });

async function sendSMS(booking, scheduleDate) {
    const date = new Date(scheduleDate.seconds * 1000);
    const startTime = new Date(booking.startTime.seconds * 1000);
    
    const dateStr = date.toLocaleDateString('en-US', { 
        weekday: 'long', 
        month: 'long', 
        day: 'numeric' 
    });
    
    const timeStr = startTime.toLocaleTimeString('en-US', { 
        hour: 'numeric', 
        minute: '2-digit',
        hour12: true 
    });
    
    const services = booking.services.map(s => s.name).join(', ');
    const totalPrice = booking.services.reduce((sum, s) => sum + s.price, 0);
    
    const message = `✨ MyBeautyCrave Booking Confirmed!\n\n` +
        `Hi ${booking.customerName}! Your appointment is confirmed:\n\n` +
        `📅 ${dateStr}\n` +
        `⏰ ${timeStr}\n` +
        `💅 Services: ${services}\n` +
        `💰 Total: $${totalPrice}\n\n` +
        `We look forward to seeing you! Reply CANCEL to cancel.`;
    
    try {
        await client.messages.create({
            body: message,
            from: twilioPhoneNumber,
            to: booking.customerPhone
        });
        
        console.log(`SMS sent to ${booking.customerPhone}`);
    } catch (error) {
        console.error('Error sending SMS:', error);
    }
}

// Handle SMS replies (for cancellations)
exports.handleSMSReply = functions.https.onRequest(async (req, res) => {
    const twiml = new twilio.twiml.MessagingResponse();
    const incomingMsg = req.body.Body.toLowerCase();
    const fromNumber = req.body.From;
    
    if (incomingMsg.includes('cancel')) {
        // Find and cancel the booking
        const db = admin.firestore();
        const schedulesRef = db.collection('schedules');
        const snapshot = await schedulesRef.get();
        
        let found = false;
        
        for (const doc of snapshot.docs) {
            const data = doc.data();
            let updated = false;
            
            data.timeSlots.forEach((slot, index) => {
                if (slot.customerPhone === fromNumber && slot.isBooked) {
                    // Cancel this booking
                    data.timeSlots[index].isBooked = false;
                    data.timeSlots[index].customerName = null;
                    data.timeSlots[index].customerPhone = null;
                    data.timeSlots[index].services = [];
                    updated = true;
                    found = true;
                }
            });
            
            if (updated) {
                await doc.ref.update({ timeSlots: data.timeSlots });
                twiml.message('Your appointment has been cancelled. We hope to see you soon! 💅');
                break;
            }
        }
        
        if (!found) {
            twiml.message('No booking found for this number. Please contact us directly.');
        }
    } else {
        twiml.message('Reply CANCEL to cancel your appointment. For other inquiries, please call us.');
    }
    
    res.type('text/xml');
    res.send(twiml.toString());
});