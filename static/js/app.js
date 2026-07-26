// ========================================
// Pegaso Airlines — JavaScript Interactivo
// ========================================

document.addEventListener('DOMContentLoaded', function() {
    
    // ─── Auto-dismiss flash messages ─────────────────────
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            alert.style.transition = 'all 0.5s ease';
            alert.style.opacity = '0';
            alert.style.transform = 'translateX(100px)';
            setTimeout(() => alert.remove(), 500);
        }, 5000);
        
        // Click to dismiss
        alert.style.cursor = 'pointer';
        alert.addEventListener('click', () => {
            alert.style.opacity = '0';
            alert.style.transform = 'translateX(100px)';
            setTimeout(() => alert.remove(), 300);
        });
    });

    // ─── Confirm dialogs for destructive actions ─────────
    document.querySelectorAll('form[data-confirm]').forEach(form => {
        form.addEventListener('submit', function(e) {
            if (!confirm(this.dataset.confirm)) {
                e.preventDefault();
            }
        });
    });

    // ─── Seat Map Interactivity ──────────────────────────
    const seatMap = document.querySelector('.seat-map');
    if (seatMap) {
        const seats = seatMap.querySelectorAll('.seat.available');
        seats.forEach(seat => {
            seat.addEventListener('mouseenter', function() {
                if (!this.classList.contains('selected')) {
                    this.style.transform = 'scale(1.15)';
                    this.style.zIndex = '10';
                }
            });
            seat.addEventListener('mouseleave', function() {
                this.style.transform = 'scale(1)';
                this.style.zIndex = '1';
            });
        });
    }

    // ─── Form validation feedback ────────────────────────
    document.querySelectorAll('form').forEach(form => {
        form.addEventListener('submit', function(e) {
            const requiredFields = this.querySelectorAll('[required]');
            let isValid = true;
            
            requiredFields.forEach(field => {
                if (!field.value.trim()) {
                    field.style.borderColor = 'var(--danger)';
                    field.style.boxShadow = '0 0 0 3px rgba(199,62,62,0.1)';
                    isValid = false;
                    
                    field.addEventListener('input', function() {
                        this.style.borderColor = '';
                        this.style.boxShadow = '';
                    }, { once: true });
                }
            });
            
            if (!isValid) {
                e.preventDefault();
            }
        });
    });

    // ─── Smooth page transitions ─────────────────────────
    document.body.style.opacity = '0';
    document.body.style.transition = 'opacity 0.3s ease';
    requestAnimationFrame(() => {
        document.body.style.opacity = '1';
    });

    // ─── Table row hover highlight ───────────────────────
    document.querySelectorAll('table tbody tr').forEach(row => {
        row.addEventListener('mouseenter', function() {
            this.style.transition = 'background-color 0.2s ease';
        });
    });

    // ─── Number input formatting ─────────────────────────
    document.querySelectorAll('input[type="number"]').forEach(input => {
        input.addEventListener('wheel', function(e) {
            e.preventDefault(); // Prevent scroll changing value
        });
    });

    // ─── Date inputs: set min to today ───────────────────
    document.querySelectorAll('input[type="date"]').forEach(input => {
        if (!input.min && !input.value) {
            const today = new Date().toISOString().split('T')[0];
            if (input.id !== 'fecha_nacimiento') {
                input.min = today;
            }
        }
    });

    // ─── Search filter for tables ────────────────────────
    const searchInput = document.getElementById('tableSearch');
    if (searchInput) {
        searchInput.addEventListener('input', function() {
            const filter = this.value.toLowerCase();
            const rows = document.querySelectorAll('table tbody tr');
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(filter) ? '' : 'none';
            });
        });
    }

    // ─── Navbar active link ──────────────────────────────
    const currentPath = window.location.pathname;
    document.querySelectorAll('.nav-links a').forEach(link => {
        if (link.getAttribute('href') === currentPath) {
            link.style.color = 'var(--accent)';
            link.style.fontWeight = '700';
        }
    });

    // ─── Boarding pass print styling ─────────────────────
    const printBtn = document.querySelector('[onclick="window.print()"]');
    if (printBtn) {
        // Add print-specific styles
        const style = document.createElement('style');
        style.media = 'print';
        style.textContent = `
            .navbar, .page-header, .flash-messages, .btn, footer { display: none !important; }
            .boarding-pass { border: 2px solid #333 !important; }
            body { background: white !important; }
        `;
        document.head.appendChild(style);
    }

    // ─── Animate stat cards on scroll ────────────────────
    const statCards = document.querySelectorAll('.stat-card');
    if (statCards.length > 0) {
        const observer = new IntersectionObserver(entries => {
            entries.forEach((entry, index) => {
                if (entry.isIntersecting) {
                    entry.target.style.animation = `fadeInUp 0.5s ease ${index * 0.1}s forwards`;
                    observer.unobserve(entry.target);
                }
            });
        });
        statCards.forEach(card => {
            card.style.opacity = '0';
            observer.observe(card);
        });
    }

    console.log('✈️ Pegaso Airlines — Sistema cargado correctamente');
});
