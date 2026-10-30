import React, { useEffect, useState } from 'react'
import logo from '../../../assets/image/TCHMB-logo.png'
import StickyNavbar from '../../../Components/Navbar'
import { useNavigate, useParams } from 'react-router-dom'
import { useDispatch } from 'react-redux'
import { useFormik } from 'formik'
import * as Yup from 'yup'
import Loader from '../../../Components/Loader/Loader'
import { Eye, EyeOff } from 'lucide-react'
import { resetPassword } from '../../../redux/actions/userActions'
import { toast } from 'react-toastify'
const ResetPassword = () => {
    const { token } = useParams();
    const navigate = useNavigate()
    const dispatch = useDispatch()
    const [load, setLoad] = useState(true)
    const [showPassword, setShowPassword] = useState(false);
    const [showPassword2, setShowPassword2] = useState(false);
    const formik = useFormik({
        initialValues: {
            password: "",
            confirmPassword: "",
        },
        validationSchema: Yup.object({
            password: Yup.string()
                .min(6, "Password must be at least 6 characters")
                .required("Required"),
            confirmPassword: Yup.string()
                .min(6, "Password must be at least 6 characters")
                .required("Required")
                .oneOf([Yup.ref('password'), null], 'Passwords must match'),
        }),
        onSubmit: (values) => {
            console.log("Form Submitted", values);
            const req = {
                password: values.password,
                confirmPassword: values.confirmPassword,
            }
            dispatch(resetPassword({token, req})).then(() => {
                toast.success("Password reset successfully. Please login with your new password.");
                navigate('/login');
            }).catch((err) => {
                toast.error(err.message)
            })
        },
    });
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
            <section className="bg-white hero flex w-full h-screen items-center justify-center p-4">
                <div className="flex flex-col w-full items-center justify-start  h-full">
                    <div className="p-4 flex flex-col items-center justify-center ">
                        <img src={logo} alt="logo" className="w-40 h-40 lg:w-52 lg:h-52" />
                        <p className='font-dm text-3xl text-center text-white'>Welcome to TCHMB Portal!</p>
                    </div>
                    <div className="w-full max-w-md min-h-72 bg-white rounded-lg shadow-md p-6">
                        {load ? (<div className="flex items-center justify-center h-[100%] w-full">
                            <Loader />
                        </div>) : <div className="w-full">
                            <h2 className="text-2xl font-bold text-gray-900 mb-4">Reset Password</h2>
                            {/* Formik Form */}
                            <form className="flex flex-col" onSubmit={formik.handleSubmit}>
                                <div className="relative">
                                    <input
                                        type={showPassword ? "text" : "password"}
                                        name="password"
                                        placeholder="Password"
                                        className="bg-gray-100 text-gray-900 border-0 rounded-md p-2 mb-2 w-full pr-10 focus:bg-gray-200 focus:outline-none focus:ring-1 focus:ring-secondary transition ease-in-out duration-150"
                                        onChange={formik.handleChange}
                                        onBlur={formik.handleBlur}
                                        value={formik.values.password}
                                        
                                    />

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

                                <div className="relative">
                                    {/* Password Input */}
                                    <input
                                        type={showPassword2 ? "text" : "password"}
                                        name="confirmPassword"
                                        placeholder="Confirm Password"
                                        className="bg-gray-100 text-gray-900 border-0 rounded-md p-2 mb-2 w-full pr-10 focus:bg-gray-200 focus:outline-none focus:ring-1 focus:ring-secondary transition ease-in-out duration-150"
                                        onChange={formik.handleChange}
                                        onBlur={formik.handleBlur}
                                        value={formik.values.confirmPassword}
                                        
                                    />
                                    {/* Toggle Button */}
                                    <button
                                        type="button"
                                        onClick={() => setShowPassword2(prev => !prev)}
                                        className="absolute right-2 top-2 text-sm text-gray-600 focus:outline-none hover:text-secondary"
                                    >
                                        {showPassword2 ? <EyeOff /> : <Eye />}
                                    </button>
                                    {formik.touched.confirmPassword && formik.errors.confirmPassword && (
                                        <p className="text-red-500 text-sm mb-2">{formik.errors.confirmPassword}</p>
                                    )}
                                </div>

                                {/* Submit Button */}
                                <button
                                    type="submit"
                                    className="bg-secondary text-white font-bold py-2 px-4 rounded-md mt-4 hover:bg-secondary-dark transition ease-in-out duration-150"
                                >
                                    Reset Password
                                </button>
                            </form>
                        </div>}
                    </div>
                </div>
            </section>
        </>
    )
}

export default ResetPassword