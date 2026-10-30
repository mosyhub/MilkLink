import React, { useState, useEffect } from "react";
import { BrowserRouter, Routes, Route, useLocation } from 'react-router-dom';
import Home from "./Pages/Home";
import Login from "./Pages/Login";
import DonorApplication from "./Pages/User/DonorApplication";
import Article from "./Pages/Article";
import SingleArticle from "./Pages/SingleArticle";
import ProtectedRoute from "./ProtectedRoute/ProtectedRoute";
import Dashboard from "./Pages/Admin/Dashboard";
import { getUser } from "./utils/helper";
import ScrollToTop from "./utils/ScrollToTop";
import { ComplexNavbar } from "./Components/Admin/AdminNavbar";
import DonorsPage from "./Pages/Admin/Donors/DonorsPage";
import SingleDonor from "./Components/Admin/Donors/SingleDonor";
import RecipientPage from "./Pages/Admin/Recipients/RecipientPage";
import SingleRecipient from "./Components/Admin/Recipients/SingleRecipient";
import Schedule from "./Pages/Admin/Calendar/Schedule";
import EditEvent from "./Components/Admin/Calendar/EditEvent";
import CreateAdmin from "./Pages/Admin/Account/CreateAdmin";
import Accounts from "./Pages/Admin/Account/Accounts";
import EmployeeLogin from "./Pages/EmployeeLogin";
import Resources from "./Pages/Admin/Resources/Resources";
import Announcement from "./Pages/Admin/Announcement/Announcement";
import CreateResources from "./Pages/Admin/Resources/CreateResources";
import EditArticle from "./Pages/Admin/Resources/EditArticle";
import Refrigerator from "./Pages/Admin/Inventory/Refrigerator";
import Profile from "./Pages/Admin/Profile/Profile";
import PickUpSchedule from "./Pages/Admin/Calendar/PickUpSchedule";
import PickUpDetails from "./Components/Admin/Calendar/Schedule/PickUpDetails";
import Attendance from "./Components/Admin/Calendar/Letting/Attendance";
import NewDonorForm from "./Components/Admin/Calendar/Letting/NewDonorForm";
import Redirect from "./Redirect";
import DonationDetails from "./Components/Admin/Calendar/Letting/DonationDetails";
import { ToastContainer } from "react-toastify";
import 'react-toastify/ReactToastify.css'
import History from "./Components/Admin/Calendar/Letting/History";
import UnpasteurizedMilk from "./Pages/Admin/Inventory/UnpasteurizedMilk";
import CollectionsTable from "./Pages/Admin/Inventory/collections/CollectionsTable";
import RedirectDetails from "./Pages/Admin/Inventory/collections/RedirectDetails";
import SidebarComponent from "./Components/Admin/SidebarComponent";
import PasteurizedMilk from "./Pages/Admin/Inventory/PasteurizedMilk";
import RequestView from "./Pages/Admin/Inventory/requests/RequestView";
import DashboardLayout from "./Pages/DashboardLayout";
import SingleRequest from "./Pages/Admin/Inventory/requests/SingleRequest";
import StaffRequestView from "./Pages/Staff/Requests/StaffRequestView";
import Submissions from "./Pages/Admin/Eligibility/Submissions";
import CreateAnnouncement from "./Pages/Admin/Announcement/CreateAnnouncement";
import SingleAnnouncement from "./Pages/Admin/Announcement/SingleAnnouncement";
import EditAnnouncement from "./Pages/Admin/Announcement/EditAnnouncement";
import InactivityHandler from "./InactivityHandler";
import 'filepond/dist/filepond.min.css';
import Archive from "./Pages/Admin/Archive/Archive";
import ArchiveLayout from "./Pages/Admin/Archive/ArchiveLayout";
import AnnouncementArchive from "./Pages/Admin/Archive/AnnouncementArchive";
import ArticleArchive from "./Pages/Admin/Archive/ArticleArchive";
import ReportsLayout from "./Pages/Admin/Reports/ReportsLayout";
import DonorsPerMonth from "./Pages/Admin/Reports/DonorsPerMonth";
import ResetPassword from "./Pages/Admin/Profile/ResetPassword";
import AboutUs from "./Pages/AboutUs";


function RoutesComponent() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/login" element={<Login />} />
      <Route path="/employee/login" element={<EmployeeLogin />} />
      <Route path="/donor-application" element={<DonorApplication />} />
      <Route path="/new-donor-form" element={<NewDonorForm />} />
      <Route path="/articles" element={<Article />} />
      <Route path="/article/:id" element={<SingleArticle />} />
      <Route path="/redirect" element={<Redirect />} />
      <Route path="/about" element={<AboutUs/>}/>
      <Route path="announcements/:id" element={<ProtectedRoute isAuthorized={true}><SingleAnnouncement /></ProtectedRoute>} />
      {/* Superadmin routes */}

      <Route path="/dashboard" element={<ProtectedRoute isAuthorized={true}><DashboardLayout /></ProtectedRoute>}>
        <Route index element={<ProtectedRoute isAdmin={true}><Dashboard /></ProtectedRoute>} />

        {/* Report paths */}
        <Route path="reports" element={<ProtectedRoute isAdmin={true}><ReportsLayout /></ProtectedRoute>}>
          <Route index element={<ProtectedRoute isAdmin={true}><DonorsPerMonth /></ProtectedRoute>} />
        </Route>

        {/* Donor paths */}
        <Route path="donors" element={<ProtectedRoute isAdmin={true}><DonorsPage /></ProtectedRoute>} />
        <Route path="donors/:id" element={<ProtectedRoute isAdmin={true}><SingleDonor /></ProtectedRoute>} />

        {/* Recipient paths */}
        <Route path="recipients" element={<ProtectedRoute isAuthorized={true}><RecipientPage /></ProtectedRoute>} />
        <Route path="recipient/:id" element={<ProtectedRoute isAuthorized={true}><SingleRecipient /></ProtectedRoute>} />

        {/* Submissions */}
        <Route path="submissions" element={<ProtectedRoute isAdmin={true}><Submissions /></ProtectedRoute>} />

        {/* Events */}
        <Route path="events" element={<ProtectedRoute isAdmin={true}><Schedule /></ProtectedRoute>} />
        <Route path="events/:id" element={<ProtectedRoute isAdmin={true}><EditEvent /></ProtectedRoute>} />
        <Route path="events/attendance/:id" element={<ProtectedRoute isAdmin={true}><Attendance /></ProtectedRoute>} />
        <Route path="event/history" element={<ProtectedRoute isAdmin={true}><History /></ProtectedRoute>} />
        <Route path="events/attendance/donations/:id" element={<ProtectedRoute isAdmin={true}><DonationDetails /></ProtectedRoute>} />

        {/* Pickup Schedules */}
        <Route path="schedules" element={<ProtectedRoute isAdmin={true}><PickUpSchedule /></ProtectedRoute>} />
        <Route path="schedules/:id" element={<ProtectedRoute isAdmin={true}><PickUpDetails /></ProtectedRoute>} />

        {/* Collections */}
        <Route path="collections" element={<ProtectedRoute isAdmin={true}><CollectionsTable /></ProtectedRoute>} />
        <Route path="collections/details/:id" element={<ProtectedRoute isAdmin={true}><RedirectDetails /></ProtectedRoute>} />

        {/* Refrigerators */}
        <Route path="inventory/refrigerator" element={<ProtectedRoute isAdmin={true}><Refrigerator /></ProtectedRoute>} />
        <Route path="inventory/fridge/unpasteurized/:id" element={<ProtectedRoute isAdmin={true}><UnpasteurizedMilk /></ProtectedRoute>} />
        <Route path="inventory/fridge/pasteurized/:id" element={<ProtectedRoute isAdmin={true}><PasteurizedMilk /></ProtectedRoute>} />

        {/* Requests */}
        <Route path="requests" element={<ProtectedRoute isAuthorized={true}><RequestView /></ProtectedRoute>} />
        <Route path="request/:id" element={<ProtectedRoute isAuthorized={true}><SingleRequest /></ProtectedRoute>} />
        {/* <Route path="create-requests" element={<ProtectedRoute isAuthorized={true}><CreateRequest /></ProtectedRoute>} /> */}

        {/* Accounts */}
        <Route path="account" element={<ProtectedRoute isAuthorized={true} isAdmin={true}><Accounts /></ProtectedRoute>} />
        <Route path="account/create" element={<ProtectedRoute isAdmin={true}><CreateAdmin /></ProtectedRoute>} />

        {/* Announcements */}
        <Route path="announcement" element={<ProtectedRoute isAdmin={true}><Announcement /></ProtectedRoute>} />
        <Route path="announcement/create" element={<ProtectedRoute isAdmin={true}><CreateAnnouncement /></ProtectedRoute>} />
        <Route path="announcement/edit/:id" element={<ProtectedRoute isAdmin={true}><EditAnnouncement /></ProtectedRoute>} />

        {/* Resources */}
        <Route path="resources" element={<ProtectedRoute isAdmin={true}><Resources /></ProtectedRoute>} />
        <Route path="resources/create" element={<ProtectedRoute isAdmin={true}><CreateResources /></ProtectedRoute>} />
        <Route path="resources/edit/:id" element={<ProtectedRoute isAdmin={true}><EditArticle /></ProtectedRoute>} />

        {/* Staff Dashboard */}

        <Route path="staff/requests" element={<ProtectedRoute isStaff={true}><StaffRequestView /></ProtectedRoute>} />


        {/* Archive */}
        <Route path="archive" element={<ProtectedRoute isAdmin={true}><ArchiveLayout /></ProtectedRoute>}>
          <Route index element={<ProtectedRoute isAdmin={true}><Archive /></ProtectedRoute>} />
          <Route path="announcements" element={<ProtectedRoute isAdmin={true}><AnnouncementArchive /></ProtectedRoute>} />
          <Route path="resources" element={<ProtectedRoute isAdmin={true}><ArticleArchive /></ProtectedRoute>} />
        </Route>


        {/* Others */}
        <Route path="profile" element={<ProtectedRoute isAuthorized={true}><Profile /></ProtectedRoute>} />
        
      </Route>
      <Route path="/password/reset/:token" element={<ResetPassword/>} />
    </Routes>
  )

}
function MainContent() {
  const location = useLocation();
  const isAdministrativePersonnelRoute = location.pathname.startsWith('/admin') || location.pathname.startsWith('/staff');
  const isAdministrativePersonnelUser = getUser() && (getUser().role === 'Admin' || getUser().role === 'Staff' || getUser().role === 'SuperAdmin');
  
  const [userDetails, setUserDetails] = useState({});
  useEffect(() => {
    if (getUser()) {
      setUserDetails({
        name: `${getUser().name.first} ${getUser().name.last}`,
        email: getUser().email,
        role: getUser().role,
      })
    }
  }, [location.pathname])

  const [isNavOpen, setIsNavOpen] = useState(false)
  return (
    <div>
      {isAdministrativePersonnelRoute && isAdministrativePersonnelUser ?
        <div className="flex">
          <SidebarComponent userDetails={userDetails} />
          <ScrollToTop />
          <div className="w-full flex flex-col gap-2">
            <ComplexNavbar isNavOpen={isNavOpen} setIsNavOpen={setIsNavOpen} />
            <RoutesComponent />
          </div>
        </div> : <RoutesComponent />}


      <ToastContainer position="bottom-right" />
    </div>
  )
}

function App() {
  return (
      <BrowserRouter>
        <InactivityHandler />
        <MainContent />
      </BrowserRouter>
  );
}

export default App;
