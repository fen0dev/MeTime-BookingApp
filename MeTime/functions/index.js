// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Configure your email transport (using Gmail as example)
// For production, use SendGrid, Mailgun, or similar
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.password
  }
});

// Or use SendGrid (recommended for production)
// const sgMail = require('@sendgrid/mail');
// sgMail.setApiKey(functions.config().sendgrid.key);

exports.sendBookingConfirmation = functions.firestore
  .document('schedules/{scheduleId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();
    
    // Find newly booked slots
    const newBookings = newData.timeSlots.filter((slot, index) => {
      const prevSlot = previousData.timeSlots[index];
      return slot.isBooked && !prevSlot.isBooked && slot.customerEmail;
    });
    
    for (const booking of newBookings) {
      await sendConfirmationEmail(booking, newData.date);
    }
  });

async function sendConfirmationEmail(booking, scheduleDate) {
  const date = new Date(scheduleDate.seconds * 1000);
  const startTime = new Date(booking.startTime.seconds * 1000);
  const totalDuration = booking.services.reduce((sum, s) => sum + s.duration, 0);
  const endTime = new Date(startTime.getTime() + totalDuration * 60000);
  const totalPrice = booking.services.reduce((sum, s) => sum + s.price, 0);
  
  const mailOptions = {
    from: '"MyBeautyCrave" <noreply@mybeautycrave.com>',
    to: booking.customerEmail,
    subject: '✨ Booking Confirmation - MyBeautyCrave',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: -apple-system, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #FF69B4, #FFB6C1); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #fff; padding: 30px; border: 1px solid #f0f0f0; }
          .service-item { background: #fafafa; padding: 15px; margin: 10px 0; border-radius: 8px; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
          .button { display: inline-block; padding: 12px 30px; background: #FF69B4; color: white; text-decoration: none; border-radius: 25px; margin: 20px 0; }
          .summary { background: #fff5f8; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .summary-row { display: flex; justify-content: space-between; margin: 10px 0; }
          .total { font-weight: bold; font-size: 18px; color: #FF69B4; border-top: 2px dashed #FFB6C1; padding-top: 10px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>✨ Booking Confirmed! ✨</h1>
            <p>Thank you for choosing MyBeautyCrave</p>
          </div>
          
          <div class="content">
            <h2>Hi ${booking.customerName}! 💕</h2>
            <p>Your appointment has been successfully booked. We can't wait to see you!</p>
            
            <div class="summary">
              <h3>Appointment Details:</h3>
              <div class="summary-row">
                <span>📅 Date:</span>
                <strong>${date.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</strong>
              </div>
              <div class="summary-row">
                <span>⏰ Time:</span>
                <strong>${formatTime(startTime)} - ${formatTime(endTime)}</strong>
              </div>
              <div class="summary-row">
                <span>📍 Location:</span>
                <strong>MyBeautyCrave Studio</strong>
              </div>
            </div>
            
            <h3>Services Booked:</h3>
            ${booking.services.map(service => `
              <div class="service-item">
                <strong>${service.emoji} ${service.name}</strong><br>
                Duration: ${service.duration} minutes | Price: $${service.price}
              </div>
            `).join('')}
            
            <div class="summary">
              <div class="summary-row total">
                <span>Total Amount:</span>
                <span>$${totalPrice}</span>
              </div>
            </div>
            
            <center>
              <a href="tel:${booking.customerPhone}" class="button">Call Us</a>
            </center>
            
            <h3>Important Reminders:</h3>
            <ul>
              <li>Please arrive 5 minutes before your appointment</li>
              <li>If you need to cancel or reschedule, please let us know at least 24 hours in advance</li>
              <li>Come with clean, product-free nails for the best results</li>
            </ul>
            
            <p>If you have any questions, feel free to reach out!</p>
            
            <p>See you soon!<br>
            The MyBeautyCrave Team 💅</p>
          </div>
          
          <div class="footer">
            <p>MyBeautyCrave | Beauty & Nail Studio</p>
            <p>This is an automated confirmation email</p>
          </div>
        </div>
      </body>
      </html>
    `
  };
  
  try {
    await transporter.sendMail(mailOptions);
    console.log('Confirmation email sent to:', booking.customerEmail);
  } catch (error) {
    console.error('Error sending email:', error);
  }
}

function formatTime(date) {
  return date.toLocaleTimeString('en-US', { 
    hour: 'numeric', 
    minute: '2-digit',
    hour12: true 
  });
}

// SMS Reminder Function (using Twilio)
exports.sendSMSReminder = functions.pubsub
  .schedule('0 9 * * *') // Run daily at 9 AM
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 1);
    
    const schedulesSnapshot = await admin.firestore()
      .collection('schedules')
      .where('date', '>=', tomorrow)
      .where('date', '<', dayAfter)
      .get();
    
    const twilio = require('twilio')(
      functions.config().twilio.account_sid,
      functions.config().twilio.auth_token
    );
    
    for (const doc of schedulesSnapshot.docs) {
      const schedule = doc.data();
      const bookedSlots = schedule.timeSlots.filter(slot => 
        slot.isBooked && slot.customerPhone && slot.smsOptIn
      );
      
      for (const slot of bookedSlots) {
        const startTime = new Date(slot.startTime.seconds * 1000);
        const message = `Hi ${slot.customerName}! 🌟 This is a reminder about your appointment tomorrow at ${formatTime(startTime)} at MyBeautyCrave. See you soon! 💅`;
        
        try {
          await twilio.messages.create({
            body: message,
            from: functions.config().twilio.phone_number,
            to: slot.customerPhone
          });
        } catch (error) {
          console.error('Error sending SMS:', error);
        }
      }
    }
  });

// Function to handle cancellations
exports.sendCancellationNotification = functions.https.onCall(async (data, context) => {
  const { scheduleId, slotId, reason } = data;
  
  try {
    const scheduleDoc = await admin.firestore()
      .collection('schedules')
      .doc(scheduleId)
      .get();
    
    if (!scheduleDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Schedule not found');
    }
    
    const schedule = scheduleDoc.data();
    const slot = schedule.timeSlots.find(s => s.id === slotId);
    
    if (!slot || !slot.customerEmail) {
      throw new functions.https.HttpsError('not-found', 'Booking not found');
    }
    
    // Send cancellation email
    const mailOptions = {
      from: '"MyBeautyCrave" <noreply@mybeautycrave.com>',
      to: slot.customerEmail,
      subject: 'Appointment Cancellation - MyBeautyCrave',
      html: `
        <div style="font-family: -apple-system, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Appointment Cancelled</h2>
          <p>Hi ${slot.customerName},</p>
          <p>Your appointment on ${new Date(schedule.date.seconds * 1000).toLocaleDateString()} at ${formatTime(new Date(slot.startTime.seconds * 1000))} has been cancelled.</p>
          ${reason ? `<p>Reason: ${reason}</p>` : ''}
          <p>We apologize for any inconvenience. Please feel free to book another appointment at your convenience.</p>
          <p>Best regards,<br>The MyBeautyCrave Team</p>
        </div>
      `
    };
    
    await transporter.sendMail(mailOptions);
    
    return { success: true };
  } catch (error) {
    console.error('Error sending cancellation email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});