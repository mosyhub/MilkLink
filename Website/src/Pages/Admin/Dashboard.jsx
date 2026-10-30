import React, { useState, useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { getMilkPerMonth, getVolumePerLocation, getDispensedMilkPerMonth, getDonorsPerMonth, getPatientsPerMonth, getRequestsPerMonth, getAvailableMilk, getExpiringMilk, getDonorLocation, getPatientHospital, getDonorAgeDemographic } from '../../redux/actions/metricActions'
import { LifebuoyIcon, UserIcon } from '@heroicons/react/24/solid'
import {
  Chart as ChartJS,
  BarElement,
  ArcElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  PointElement,
  Legend,
} from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';
import { Bar, Pie } from 'react-chartjs-2';
import { Accordion, AccordionHeader, AccordionBody, Card, CardHeader, Typography } from '@material-tailwind/react';
import { formatNumber } from '../../utils/helper'
import { donorAgeDemographic, donorsPerBarangay, milkCollectedChartData, milkDonatedPerBarangay, monthlyDispensedMilkChartData, monthlyDonorsChartData, monthlyPatientsChartData, patientPerHospital } from '../../data/metricsData';
import { useCountUp } from '../../utils/hooks/useCountUp';
import { useBreadcrumb } from '../../Components/Breadcrumb/BreadcrumbContext';
import PropTypes from 'prop-types'
// Register required components
ChartJS.register(BarElement, PointElement, ArcElement, CategoryScale, LinearScale, Tooltip, Legend, ChartDataLabels);


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
  id: PropTypes.string.isRequired,
  open: PropTypes.string.isRequired,
}
const Dashboard = () => {
  const { setBreadcrumb } = useBreadcrumb();
  const dispatch = useDispatch();
  const { statsLoading, monthlyDonorsLoading, expiringLoading, dispensedMilkLoading, monthlyPatientsLoading, monthlyRequestsLoading, availableLoading, stats, available, monthlyDonors, patientHospital, donorLocation, volumePerLocation, expiring, dispensedMilk, monthlyPatients, monthlyRequests, donorAge } = useSelector((state) => state.metrics);
  useEffect(() => {
    setBreadcrumb([
      { name: "Dashboard", path: "/dashboard" },
    ])
  }, [])
  useEffect(() => {
    dispatch(getMilkPerMonth());
    dispatch(getDispensedMilkPerMonth());
    dispatch(getDonorsPerMonth());
    dispatch(getPatientsPerMonth());
    dispatch(getRequestsPerMonth());
    dispatch(getAvailableMilk());
    dispatch(getExpiringMilk());
    dispatch(getVolumePerLocation());
    dispatch(getDonorLocation());
    dispatch(getPatientHospital());
    dispatch(getDonorAgeDemographic());
  }, [dispatch])

  const animatedAvailable = useCountUp(available, availableLoading, 800, 20);
  const animatedExpiring = useCountUp(expiring, expiringLoading, 800, 20);
  const animatedMonthlyDonors = useCountUp(monthlyDonors?.total?.total, monthlyDonorsLoading, 800, 20);
  const animatedMonthlyPatients = useCountUp(monthlyPatients?.total?.total, monthlyPatientsLoading, 800, 20);
  const animatedDispensedMilk = useCountUp(dispensedMilk?.total?.total, dispensedMilkLoading, 800, 20);
  const animatedStats = useCountUp(stats?.total?.total, statsLoading, 800, 20);
  const animatedCompletedRequests = useCountUp(monthlyRequests?.completed, monthlyRequestsLoading, 800, 20);
  const animatedPendingRequests = useCountUp(monthlyRequests?.pending, monthlyRequestsLoading, 800, 20);

  const { data: statsData, options: statsOptions } = milkCollectedChartData(stats);
  const { data: donorData, options: donorOptions } = monthlyDonorsChartData(monthlyDonors);
  const { data: patientData, options: patientOptions } = monthlyPatientsChartData(monthlyPatients);
  const { data: dispensedData, options: dispensedOptions } = monthlyDispensedMilkChartData(dispensedMilk);
  const { data: volumeLocationData, options: volumeLocationOptions } = milkDonatedPerBarangay(volumePerLocation);
  const { data: donorLocationData, options: donorLocationOptions } = donorsPerBarangay(donorLocation);
  const { data: patientHospitalData, options: patientHospitalOptions } = patientPerHospital(patientHospital);
  const { data: donorAgeData, options: donorAgeOptions } = donorAgeDemographic(donorAge);
  const [open, setOpen] = useState(0);
  const handleOpen = (value) => {
    setOpen(open === value ? 0 : value);
  };
  useEffect(() => {
    if (donorLocation) {
      console.log(donorLocation)
    }
  }, [donorLocation])
  return (
    <div className="h-[calc(100vh-4rem)] overflow-y-auto w-full">
      {/* Cards */}
      <div className="min-h-fit grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 w-full p-4">
        <div className="flex flex-wrap justify-between items-center gap-4 rounded-lg border border-secondary bg-white p-6">
          <span style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }} className="font-parkinsans font-medium text-gray-900">Available Pasteurized Milk</span>
          <div className="w-full justify-end flex items-baseline gap-2">
            <span className="font-bold text-gray-900" style={{ fontSize: 'clamp(2rem, 2vw, 3rem)' }}>{animatedAvailable.toLocaleString()}</span>
            <span className="font-semibold text-secondary" style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }}> ml </span>
          </div>
        </div>
        <div className="flex flex-wrap justify-between items-center gap-4 rounded-lg border border-secondary bg-white p-6">
          <span style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }} className="font-parkinsans font-medium text-gray-900">Unpasteurized Milk</span>
          <div className="flex items-baseline justify-end w-full gap-2">
            <span className="font-semibold text-gray-900" style={{ fontSize: 'clamp(2rem, 2vw, 3rem)' }}> {animatedExpiring.toLocaleString()} </span>
            <span className="font-semibold text-secondary" style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }}> ml </span>
          </div>
        </div>
        <div className="flex flex-wrap justify-between items-center gap-4 rounded-lg border border-secondary bg-white p-6">
          <span style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }} className="font-parkinsans font-medium text-gray-900">Total Milk Distributed</span>
          <div className="flex items-baseline justify-end w-full gap-2">
            <span className="font-semibold text-gray-900" style={{ fontSize: 'clamp(2rem, 2vw, 3rem)' }}> {animatedDispensedMilk.toLocaleString()} </span>
            <span className="font-semibold text-secondary" style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }}>ml</span>
          </div>
        </div>
        <div className="flex flex-wrap justify-between items-center gap-4 rounded-lg border border-secondary bg-white p-6">
          <span style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }} className="font-parkinsans font-medium text-gray-900">Total Milk Collected</span>
          <div className="flex items-baseline justify-end w-full gap-2">
            <span className="font-semibold text-gray-900" style={{ fontSize: 'clamp(2rem, 2vw, 3rem)' }}> {animatedStats.toLocaleString()} </span>
            <span className="font-semibold text-secondary" style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }}> ml </span>
          </div>
        </div>
        <div className="flex flex-wrap justify-between items-center gap-4 rounded-lg border border-secondary bg-white p-6">
          <span style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }} className="font-parkinsans font-medium text-gray-900">Total Donors</span>
          <div className="flex items-center justify-end w-full gap-2">
            <span className="font-semibold text-gray-900" style={{ fontSize: 'clamp(2rem, 2vw, 3rem)' }}> {animatedMonthlyDonors.toLocaleString()} </span>
            <UserIcon className="text-secondary w-8 h-8" />
          </div>
        </div>
        <div className="flex flex-wrap justify-between items-center gap-4 rounded-lg border border-secondary bg-white p-6">
          <span style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }} className="font-parkinsans font-medium text-gray-900">Total Recipients</span>
          <div className="flex items-center justify-end w-full gap-2">
            <span className="font-semibold text-gray-900" style={{ fontSize: 'clamp(2rem, 2vw, 3rem)' }}> {animatedMonthlyPatients.toLocaleString()} </span>
            <UserIcon className="text-secondary w-8 h-8" />
          </div>
        </div>
        <div className="flex flex-wrap justify-between items-center gap-4 rounded-lg border border-secondary bg-white p-6">
          <span style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }} className="font-parkinsans font-medium text-gray-900">Completed Requests</span>
          <div className="flex items-center justify-end w-full gap-2">
            <span className="font-semibold text-gray-900" style={{ fontSize: 'clamp(2rem, 2vw, 3rem)' }}> {animatedCompletedRequests.toLocaleString()} </span>
            <LifebuoyIcon className="text-secondary w-8 h-8" />
          </div>
        </div>
        <div className="flex flex-wrap justify-between items-center gap-4 rounded-lg border border-secondary bg-white p-6">
          <span style={{ fontSize: 'clamp(0.8rem, 2vw, 1.5rem)' }} className="font-parkinsans font-medium text-gray-900">Pending Requests</span>
          <div className="flex items-center justify-end w-full gap-2">
            <span className="font-semibold text-gray-900" style={{ fontSize: 'clamp(2rem, 2vw, 3rem)' }}> {animatedPendingRequests.toLocaleString()} </span>
            <LifebuoyIcon className="text-secondary w-8 h-8" />
          </div>
        </div>
      </div>
      {/* Charts */}
      <div className="p-4">
        <Accordion open={open === 1} icon={<Icon id={1} open={open} />}>
          <AccordionHeader onClick={() => handleOpen(1)} className="font-sofia">Milk Metrics</AccordionHeader>
          <AccordionBody>
            <div className="grid grid-cols-2 gap-4 min-h-fit w-full p-4">
              <Card className="p-4 border shadow-lg">
                <CardHeader shadow={false} floated={false}>
                  <Typography variant="h5" color="blue-gray">Milk Collected Per Month {stats && stats.total ? `(${formatNumber(stats.total.total)} ml)` : '(0 ml)'}</Typography>
                </CardHeader>
                <Bar data={statsData} options={statsOptions} />
              </Card>
              <Card className="p-4 border shadow-lg">
                <CardHeader shadow={false} floated={false}>
                  <Typography variant="h5" color="blue-gray">Dispensed Milk Per Month {dispensedMilk && dispensedMilk.total ? `(${formatNumber(dispensedMilk.total.total)} ml)` : '(0 ml)'}</Typography>
                </CardHeader>
                <Bar data={dispensedData} options={dispensedOptions} />
              </Card>
              <Card className="p-4 border shadow-lg">
                <CardHeader shadow={false} floated={false}>
                  <Typography variant="h5" color="blue-gray">Collected Milk Per Barangay {volumePerLocation && volumePerLocation.total ? `(${formatNumber(volumePerLocation.total)} ml)` : '(0 ml)'}</Typography>
                </CardHeader>
                <div className="max-h-[600px] h-full">
                  <Pie data={volumeLocationData} options={volumeLocationOptions}/>
                </div>

              </Card>
            </div>
          </AccordionBody>
        </Accordion>

        <Accordion open={open === 2} icon={<Icon id={2} open={open} />}>
          <AccordionHeader onClick={() => handleOpen(2)} className="font-sofia">Donor Metrics</AccordionHeader>
          <AccordionBody>
            <div className="grid grid-cols-2 gap-4 min-h-fit w-full p-4">
              <Card className="p-4 border shadow-lg">
                <CardHeader shadow={false} floated={false}>
                  <Typography variant="h5" color="blue-gray">Donors Per Month {monthlyDonors && monthlyDonors.total ? `(${formatNumber(monthlyDonors.total?.total)})` : '(0)'}</Typography>
                </CardHeader>
                <Bar data={donorData} options={donorOptions} />
              </Card>
              <Card className="p-4 border shadow-lg">
                <CardHeader shadow={false} floated={false}>
                  <Typography variant="h5" color="blue-gray">Donors Per Barangay {donorLocation && donorLocation.total ? `(${formatNumber(donorLocation.total)})` : '(0)'}</Typography>
                </CardHeader>
                <div className="max-h-[600px] h-full">
                  <Pie data={donorLocationData} options={donorLocationOptions} />
                </div>
              </Card>
              <Card className="p-4 border shadow-lg">
                <CardHeader shadow={false} floated={false}>
                  <Typography variant="h5" color="blue-gray">Donors Age Distribution {donorAge && donorAge.total ? `(${formatNumber(donorAge.total)})` : '(0)'}</Typography>
                </CardHeader>
                <div className="max-h-[400px] flex items-center justify-center p-4">
                  <Bar data={donorAgeData} options={donorAgeOptions} />
                </div>
              </Card>
            </div>
          </AccordionBody>
        </Accordion>
        <Accordion open={open === 3} icon={<Icon id={3} open={open} />}>
          <AccordionHeader onClick={() => handleOpen(3)} className="font-sofia">Patient Metrics</AccordionHeader>
          <AccordionBody>
            <div className="grid grid-cols-2 gap-4 min-h-fit w-full p-4">
              <Card className="p-4 border shadow-lg">
                <CardHeader shadow={false} floated={false}>
                  <Typography variant="h5" color="blue-gray">Patients Per Month {monthlyPatients && monthlyPatients.total ? `(${formatNumber(monthlyPatients.total.total)})` : '(0)'}</Typography>
                </CardHeader>
                <Bar data={patientData} options={patientOptions} />
              </Card>
              <Card className="p-4 border shadow-lg">
                <CardHeader shadow={false} floated={false}>
                  <Typography variant="h5" color="blue-gray">Patients Per Hospital {patientHospital && patientHospital.total ? `(${formatNumber(patientHospital.total)})` : '(0)'}</Typography>
                </CardHeader>
                <div className="max-h-[400px] h-full">
                  <Pie data={patientHospitalData} options={patientHospitalOptions} />
                </div>
              </Card>
            </div>
          </AccordionBody>
        </Accordion>
      </div>
    </div>
  )
}

export default Dashboard