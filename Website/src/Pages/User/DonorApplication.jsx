import React, { useEffect } from 'react'

const DonorApplication = () => {
  const formURL = `https://tally.so/r/3NM8XQ`;
    useEffect(() => {
      // Load the Tally embed script
      const script = document.createElement("script");
      script.src = "https://tally.so/widgets/embed.js";
      script.async = true;
      document.body.appendChild(script);

      // Cleanup the script when the component is unmounted
      return () => {
        document.body.removeChild(script);
      };
    }, []);

  return (
    <div style={{ height: "100vh", margin: 0, overflow: "hidden" }}>
      <iframe
        data-tally-src={formURL}
        width="100%"
        height="100%"
        frameBorder="0"
        marginHeight="0"
        marginWidth="0"
        title="Taguig City Human Milk Bank Standard Interview Form"
      ></iframe>
    </div>
  );
}

export default DonorApplication