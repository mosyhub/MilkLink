import { useEffect } from "react";

const NewDonorForm = () => {
    useEffect(() => {
        // Dynamically load the Tally embed script
        const script = document.createElement("script");
        script.src = "https://tally.so/widgets/embed.js";
        script.async = true;
        document.body.appendChild(script);

        return () => {
            document.body.removeChild(script); // Cleanup on unmount
        };
    }, []);

    return (
        <div style={{ height: "100vh", margin: 0, overflow: "hidden" }}>
            <iframe
                data-tally-src="https://tally.so/r/wbv1XZ"
                width="100%"
                height="100%"
                frameBorder="0"
                title="Attendance (Donor Details)"
               
            ></iframe>
        </div>
    );
};

export default NewDonorForm;
