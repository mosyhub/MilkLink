import React, { useState, useEffect } from 'react'
import StickyNavbar from '../Components/Navbar'
import { useDispatch, useSelector } from 'react-redux'
import { loginUser } from '../redux/actions/userActions'
import { useFormik } from 'formik'
import * as Yup from 'yup'
import { Link, useNavigate } from 'react-router-dom'
import logo from '../assets/image/TCHMB-logo.png'
import { toast } from 'react-toastify'
import { resetError } from '../redux/slices/userSlice'
import Loader from '../Components/Loader/Loader'
import { Eye, EyeOff } from 'lucide-react'

const EmployeeLogin = () => {
    const navigate = useNavigate()
    const dispatch = useDispatch()
    const { isLoggedIn, userDetails, error, loading } = useSelector(state => state.users)
    const [load, setLoad] = useState(true)
    const [showPassword, setShowPassword] = useState(false);
    const formik = useFormik({
        initialValues: {
            employeeID: "", // Changed from email to employeeID
            password: "",
        },
        validationSchema: Yup.object({
            employeeID: Yup.string()
                .matches(/^\d{3,}$/, "Employee ID must be at least 3 digits") // Ensure numeric with 3+ digits
                .required("Employee ID is required"),
            password: Yup.string()
                .min(6, "Password must be at least 6 characters")
                .required("Password is required"),
        }),
        onSubmit: (values) => {
            console.log("Form Submitted", values);

            // Prepare FormData
            const formData = new FormData();
            formData.set('employeeID', values.employeeID); // Changed from email to employeeID
            formData.set('password', values.password);
            formData.set('isEmp', true);
            dispatch(loginUser(formData))
        },
    });
    useEffect(() => {

        if (isLoggedIn && (userDetails.role === 'Admin' || userDetails.role === 'SuperAdmin')) {
            navigate('/dashboard');
            toast.success(`Welcome, ${userDetails.name.first} ${userDetails.name.last}`, { position: "bottom-right" });

        }
        else if (isLoggedIn && userDetails.role === 'Staff') {
            navigate('/dashboard/recipients');
            toast.success(`Welcome, ${userDetails.name.first} ${userDetails.name.last}`, { position: "bottom-right" });
        }
        else if (isLoggedIn) {
            navigate('/');
            toast.success(`Welcome, ${userDetails.name.first} ${userDetails.name.last}`, { position: "bottom-right" });
        }

        if (error) {
            toast.error(error, { position: "bottom-right" });
            dispatch(resetError());
        }
    }, [isLoggedIn, error])
    useEffect(() => {
        // Simulate a delay (e.g. 500ms)
        const timer = setTimeout(() => {
            setLoad(false);
        }, 500);

        // Cleanup timer on unmount
        return () => clearTimeout(timer);
    }, []);
    return (
        <>
            <StickyNavbar />

            <section

                className="bg-white hero flex w-full h-screen items-center justify-center p-4">

                <div className="flex flex-col w-full items-center justify-start  h-full">
                    <div className="p-4 flex flex-col items-center justify-center ">
                        <img src={logo} alt="logo" className="w-40 h-40 lg:w-52 lg:h-52" />
                        <p className='font-dm text-3xl text-center text-white'>Welcome to TCHMB Portal!</p>
                    </div>


                    <div className="w-full max-w-md min-h-72 bg-white rounded-lg shadow-md p-6">
                        {load ? (<div className="flex items-center justify-center h-[100%]">
                            <Loader />
                        </div>) : <div className="w-full">
                            <h2 className="text-2xl font-bold text-gray-900 mb-4">Employee Login</h2>
                            {/* Formik Form */}
                            <form className="flex flex-col" onSubmit={formik.handleSubmit}>
                                {/* Employee ID Input */}
                                <input
                                    type="text"
                                    name="employeeID"
                                    placeholder="Employee ID"
                                    className="bg-gray-100 text-gray-900 border-0 rounded-md p-2 mb-2 focus:bg-gray-200 focus:outline-none focus:ring-1 focus:ring-secondary transition ease-in-out duration-150"
                                    onChange={formik.handleChange}
                                    onBlur={formik.handleBlur}
                                    value={formik.values.employeeID}
                                />
                                {formik.touched.employeeID && formik.errors.employeeID && (
                                    <p className="text-red-500 text-sm mb-2">{formik.errors.employeeID}</p>
                                )}


                                <div className="relative">
                                    {/* Password Input */}
                                    <input
                                        type={showPassword ? "text" : "password"}
                                        name="password"
                                        placeholder="Password"
                                        className="bg-gray-100 text-gray-900 border-0 rounded-md p-2 mb-2 w-full pr-10 focus:bg-gray-200 focus:outline-none focus:ring-1 focus:ring-secondary transition ease-in-out duration-150"
                                        onChange={formik.handleChange}
                                        onBlur={formik.handleBlur}
                                        value={formik.values.password}
                                    />
                                    {/* Toggle Button */}
                                    <button
                                        type="button"
                                        onClick={() => setShowPassword(prev => !prev)}
                                        className="absolute right-2 top-2 text-sm text-gray-600 focus:outline-none hover:text-secondary"
                                    >
                                        {showPassword ? <EyeOff /> : <Eye />}
                                    </button>
                                    {formik.touched.password && formik.errors.password && (
                                        <p className="text-red-500 text-sm mb-2">{formik.errors.password}</p>
                                    )}
                                </div>



                                {/* Signup Link */}
                                <p className="text-gray-900 mt-4">
                                    Sign in with email?{" "}
                                    <Link to="/login" className="text-sm text-secondary hover:underline mt-4">
                                        Login here.
                                    </Link>
                                </p>

                                {/* Submit Button */}
                                {loading ? (<button
                                    type="submit"
                                    className="bg-gray-600 text-white font-bold py-2 px-4 rounded-md mt-4 flex justify-center items-center"
                                >
                                    <Loader size="small"/>
                                </button>) : (<button
                                    type="submit"
                                    className="bg-secondary text-white font-bold py-2 px-4 rounded-md mt-4 hover:bg-secondary-dark transition ease-in-out duration-150"
                                >
                                    Login
                                </button>)}

                            </form>
                        </div>}
                    </div>



                </div>


            </section>

        </>

    )
}

export default EmployeeLogin