import img1 from "../assets/image/recipients.jpg";
import img2 from "../assets/image/milk-letting-event-1.jpg";
import img3 from "../assets/image/world-human-milk-donors-day-2.jpg";
import img4 from "../assets/image/donors.jpg";
import img5 from "../assets/image/tokens.jpg";
import img6 from "../assets/image/donor2.jpg";
export function DefaultGallery() {
    const data = [
        {
            imageLink:
                img6,
            description: "Get tested for free before donating!\nWe provide free health screenings to ensure the safety of our donors and recipients."
        },
        {
            imageLink:
                img2,
            style: { objectPosition: '20% 10%' },
            description: "Be part of our Grand Milk Letting Event!\nHelp save lives by donating breastmilk to infants in need."
        },
        {
            imageLink:
                img3,
            description: "Celebrate World Human Milk Donors Day with us!\nWhere we honor the selfless act of donating breastmilk to infants in need."
        },
        {
            imageLink:
                img4,
            description: "Donate your breastmilk wherever you are!\nWe collect donations from all 38 barangays in Taguig City."
        },
        {
            imageLink:
                img5,
            style: { objectPosition: '20% 70%' },
            description: "Receive tokens of appreciation for your donation!\nWe give out tokens and free services to our donors as a sign of our gratitude."
        },
        {

            imageLink:
                img1,
            style: { objectPosition: '20% 40%' },
            description: `"Bilang mayor ng city, proud na proud ako dahil kumikilos ang ating mga residente tungo sa tamang landasin — ang i-promote ang breastfeeding." \n - Mayor Lani Cayetano`
        },

    ];

    return (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3">
            {data.map(({ imageLink, style, description }) => (
                <div key={imageLink} className="relative group">
                    <img
                        className="h-40 w-full max-w-full rounded-lg object-cover object-center"
                        src={imageLink}
                        alt="gallery-photo"
                        style={style}
                    />
                    {/* Description Overlay */}
                    <div
                        className="absolute inset-0 flex items-center justify-center bg-pink-900 bg-opacity-50 text-white opacity-0 transition-opacity duration-300 group-hover:opacity-100 rounded-lg"
                    >
                        <p className="text-center px-2 font-varela" style={{ whiteSpace: 'pre-wrap' }}>{description}</p>
                    </div>
                </div>
            ))}
        </div>
    );
}
