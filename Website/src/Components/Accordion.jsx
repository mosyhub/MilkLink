import React from "react";
import {
  Accordion,
  AccordionHeader,
  AccordionBody,
} from "@material-tailwind/react";
import PropTypes from "prop-types";
function Icon({ id, open }) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      strokeWidth={2}
      stroke="currentColor"
      className={`${id === open ? "rotate-180" : ""} h-5 w-5 transition-transform`}
    >
      <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
    </svg>
  );
}
Icon.propTypes = {
  id: PropTypes.string.isRequired,   // or PropTypes.number, depending on your use
  open: PropTypes.string.isRequired, // same here
};
export function AccordionCustomIcon() {
  const [open, setOpen] = React.useState(0);

  const handleOpen = (value) => setOpen(open === value ? 0 : value);

  return (
    <>
      <Accordion open={open === 1} icon={<Icon id={1} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(1)}>What is the purpose of the Taguig City Human Milk Bank?</AccordionHeader>
        <AccordionBody>
          The Human Milk Bank provides pasteurized donor human milk to infants who need it, especially premature and sick babies whose mothers may not be able to provide breast milk.
        </AccordionBody>
      </Accordion>
      <Accordion open={open === 2} icon={<Icon id={2} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(2)}>
          Who can donate breast milk to the Taguig City Human Milk Bank?
        </AccordionHeader>
        <AccordionBody>
          Healthy, lactating mothers with an excess supply of breast milk and who meet the eligibility criteria set by the milk bank can donate.
        </AccordionBody>
      </Accordion>
      <Accordion open={open === 3} icon={<Icon id={3} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(3)}>
          How can I become a breast milk donor?
        </AccordionHeader>
        <AccordionBody>
          Interested mothers can contact the milk bank for screening, which includes filling out a health questionnaire, providing a medical history, and undergoing necessary blood tests.
        </AccordionBody>
      </Accordion>
      <Accordion open={open === 4} icon={<Icon id={4} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(4)}>
          Is the donated breast milk safe for babies?
        </AccordionHeader>
        <AccordionBody>
          Yes, all donated breast milk is pasteurized to eliminate harmful bacteria and undergoes rigorous quality control measures to ensure safety and nutritional value.
        </AccordionBody>
      </Accordion>
      <Accordion open={open === 5} icon={<Icon id={5} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(5)}>
          Who can receive donated breast milk?
        </AccordionHeader>
        <AccordionBody>
          Donated milk is provided to preterm or sick infants in hospitals, neonatal intensive care units (NICUs), and sometimes to healthy infants with specific needs when their mothers are unable to breastfeed.
        </AccordionBody>
      </Accordion>
      <Accordion open={open === 6} icon={<Icon id={6} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(6)}>
          What are the benefits of using donor breast milk?
        </AccordionHeader>
        <AccordionBody>
          Donor breast milk provides essential nutrients, antibodies, and protection against infections, promoting better health outcomes for vulnerable infants.
        </AccordionBody>
      </Accordion>
      <Accordion open={open === 7} icon={<Icon id={7} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(7)}>
          Is there a cost to receive donated breast milk?
        </AccordionHeader>
        <AccordionBody>
          The milk bank may charge a processing fee to cover pasteurization and handling, but it is usually subsidized or free for eligible families. Contact the milk bank for details.
        </AccordionBody>
      </Accordion>
      <Accordion open={open === 8} icon={<Icon id={8} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(8)}>
          Can I donate breast milk if I am taking medication?
        </AccordionHeader>
        <AccordionBody>
          It depends on the medication. The milk bank will evaluate your medical history and determine if you are eligible to donate.
        </AccordionBody>
      </Accordion>
      <Accordion open={open === 9} icon={<Icon id={9} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(9)}>
          How is the breast milk collected and stored?
        </AccordionHeader>
        <AccordionBody>
          Donors are provided with sterile containers and instructions for proper milk expression and storage. Milk is stored frozen and transported to the milk bank for processing.
        </AccordionBody>
      </Accordion>
      <Accordion open={open === 10} icon={<Icon id={10} open={open} />}>
        <AccordionHeader onClick={() => handleOpen(10)}>
          How can I contact the Taguig City Human Milk Bank?
        </AccordionHeader>
        <AccordionBody>
          You can reach the milk bank via their official contact number, email, or by visiting their office in Taguig City. Check their website or social media pages for more information.
        </AccordionBody>
      </Accordion>
    </>
  );
}