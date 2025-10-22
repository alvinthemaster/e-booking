// Global variables
let currentTicket = null;
let qrCodeInstance = null;

// Search for ticket
async function searchTicket() {
    const bookingId = document.getElementById('bookingIdInput').value.trim();
    const errorDiv = document.getElementById('errorMessage');
    const searchBtn = document.getElementById('searchBtn');
    const btnText = document.getElementById('btnText');
    const btnLoader = document.getElementById('btnLoader');

    // Validate input
    if (!bookingId) {
        showError('Please enter a Booking ID');
        return;
    }

    // Show loading state
    searchBtn.disabled = true;
    btnText.style.display = 'none';
    btnLoader.style.display = 'block';
    errorDiv.style.display = 'none';

    try {
        // Query Firestore for the booking
        const bookingsRef = db.collection('bookings');
        const querySnapshot = await bookingsRef.where('bookingId', '==', bookingId).limit(1).get();

        if (querySnapshot.empty) {
            showError('No ticket found with this Booking ID. Please check and try again.');
            return;
        }

        // Get the booking document
        const bookingDoc = querySnapshot.docs[0];
        const booking = { id: bookingDoc.id, ...bookingDoc.data() };

        // Store current ticket
        currentTicket = booking;

        // Display the ticket
        displayTicket(booking);

    } catch (error) {
        console.error('Error fetching ticket:', error);
        showError('An error occurred while fetching your ticket. Please try again later.');
    } finally {
        // Reset button state
        searchBtn.disabled = false;
        btnText.style.display = 'block';
        btnLoader.style.display = 'none';
    }
}

// Display ticket information
function displayTicket(booking) {
    // Hide search section, show ticket section
    document.getElementById('searchSection').style.display = 'none';
    document.getElementById('ticketSection').style.display = 'block';

    // Set status badge
    const statusBadge = document.getElementById('statusBadge');
    const status = booking.status || 'pending';
    statusBadge.textContent = status.charAt(0).toUpperCase() + status.slice(1);
    statusBadge.className = `status-badge ${status}`;

    // Booking Information
    document.getElementById('ticketBookingId').textContent = booking.bookingId || 'N/A';
    document.getElementById('ticketBookingDate').textContent = formatDate(booking.bookingDate);
    document.getElementById('ticketStatus').textContent = status.charAt(0).toUpperCase() + status.slice(1);

    // Passenger Information
    document.getElementById('ticketName').textContent = booking.passengerName || 'N/A';
    document.getElementById('ticketContact').textContent = booking.contactNumber || 'N/A';
    document.getElementById('ticketEmail').textContent = booking.email || 'N/A';

    // Trip Details
    document.getElementById('ticketRoute').textContent = `${booking.origin || 'N/A'} → ${booking.destination || 'N/A'}`;
    document.getElementById('ticketVan').textContent = `${booking.vanPlateNumber || 'N/A'} (${booking.vehicleType || 'van'})`;
    document.getElementById('ticketDriver').textContent = booking.driverName || 'N/A';
    document.getElementById('ticketDeparture').textContent = formatDateTime(booking.departureTime);

    // Seats & Payment
    displaySeats(booking.seatNumbers || []);
    document.getElementById('ticketAmount').textContent = `₱${(booking.totalAmount || 0).toFixed(2)}`;
    document.getElementById('ticketPayment').textContent = booking.paymentMethod || 'N/A';
    document.getElementById('ticketPaymentStatus').textContent = booking.paymentStatus || 'N/A';

    // Generate QR Code
    generateQRCode(booking.bookingId);

    // Scroll to top
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Display seats with badges
function displaySeats(seats) {
    const seatsContainer = document.getElementById('ticketSeats');
    
    if (!seats || seats.length === 0) {
        seatsContainer.innerHTML = '<span>No seats</span>';
        return;
    }

    seatsContainer.innerHTML = seats.map(seat => 
        `<span class="seat">${seat}</span>`
    ).join('');
}

// Generate QR Code
function generateQRCode(bookingId) {
    const qrContainer = document.getElementById('qrCode');
    qrContainer.innerHTML = ''; // Clear previous QR code

    try {
        qrCodeInstance = new QRCode(qrContainer, {
            text: bookingId,
            width: 200,
            height: 200,
            colorDark: "#000000",
            colorLight: "#ffffff",
            correctLevel: QRCode.CorrectLevel.H
        });
    } catch (error) {
        console.error('Error generating QR code:', error);
        qrContainer.innerHTML = '<p style="color: red;">Failed to generate QR code</p>';
    }
}

// Format date
function formatDate(timestamp) {
    if (!timestamp) return 'N/A';
    
    let date;
    if (timestamp.toDate) {
        // Firestore Timestamp
        date = timestamp.toDate();
    } else if (timestamp instanceof Date) {
        date = timestamp;
    } else {
        date = new Date(timestamp);
    }

    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

// Format date and time
function formatDateTime(timestamp) {
    if (!timestamp) return 'N/A';
    
    let date;
    if (timestamp.toDate) {
        // Firestore Timestamp
        date = timestamp.toDate();
    } else if (timestamp instanceof Date) {
        date = timestamp;
    } else {
        date = new Date(timestamp);
    }

    return date.toLocaleString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Show error message
function showError(message) {
    const errorDiv = document.getElementById('errorMessage');
    errorDiv.textContent = message;
    errorDiv.style.display = 'block';
}

// Search another ticket
function searchAnother() {
    document.getElementById('searchSection').style.display = 'block';
    document.getElementById('ticketSection').style.display = 'none';
    document.getElementById('bookingIdInput').value = '';
    document.getElementById('errorMessage').style.display = 'none';
    currentTicket = null;
    qrCodeInstance = null;
}

// Print ticket
function printTicket() {
    window.print();
}

// Download ticket as PDF
function downloadTicket() {
    if (!currentTicket) {
        alert('No ticket data available');
        return;
    }

    try {
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();

        // Add title
        doc.setFontSize(20);
        doc.setTextColor(33, 150, 243);
        doc.text('UVexpress E-Ticket', 105, 20, { align: 'center' });

        // Add booking ID
        doc.setFontSize(14);
        doc.setTextColor(0, 0, 0);
        doc.text(`Booking ID: ${currentTicket.bookingId}`, 20, 40);

        // Add passenger info
        doc.setFontSize(12);
        doc.text('Passenger Information:', 20, 55);
        doc.setFontSize(10);
        doc.text(`Name: ${currentTicket.passengerName || 'N/A'}`, 30, 65);
        doc.text(`Contact: ${currentTicket.contactNumber || 'N/A'}`, 30, 72);
        doc.text(`Email: ${currentTicket.email || 'N/A'}`, 30, 79);

        // Add trip info
        doc.setFontSize(12);
        doc.text('Trip Details:', 20, 95);
        doc.setFontSize(10);
        doc.text(`Route: ${currentTicket.origin || 'N/A'} → ${currentTicket.destination || 'N/A'}`, 30, 105);
        doc.text(`Van: ${currentTicket.vanPlateNumber || 'N/A'}`, 30, 112);
        doc.text(`Driver: ${currentTicket.driverName || 'N/A'}`, 30, 119);
        doc.text(`Departure: ${formatDateTime(currentTicket.departureTime)}`, 30, 126);

        // Add seats and payment
        doc.setFontSize(12);
        doc.text('Booking Details:', 20, 142);
        doc.setFontSize(10);
        const seats = currentTicket.seatNumbers?.join(', ') || 'N/A';
        doc.text(`Seats: ${seats}`, 30, 152);
        doc.text(`Total Amount: ₱${(currentTicket.totalAmount || 0).toFixed(2)}`, 30, 159);
        doc.text(`Payment Method: ${currentTicket.paymentMethod || 'N/A'}`, 30, 166);
        doc.text(`Status: ${currentTicket.status || 'N/A'}`, 30, 173);

        // Add QR code if available
        const qrCanvas = document.querySelector('#qrCode canvas');
        if (qrCanvas) {
            const qrImage = qrCanvas.toDataURL('image/png');
            doc.addImage(qrImage, 'PNG', 80, 185, 50, 50);
            doc.setFontSize(8);
            doc.text('Show this QR code when boarding', 105, 245, { align: 'center' });
        }

        // Save PDF
        doc.save(`E-Ticket-${currentTicket.bookingId}.pdf`);
    } catch (error) {
        console.error('Error generating PDF:', error);
        alert('Failed to generate PDF. Please try again.');
    }
}

// Allow Enter key to search
document.getElementById('bookingIdInput')?.addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        searchTicket();
    }
});

// Initialize on page load
window.addEventListener('DOMContentLoaded', () => {
    console.log('E-Ticket Viewer loaded successfully');
});
