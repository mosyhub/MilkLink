import React, { useEffect } from "react";

// @material-tailwind/react
import {
  Input,
  Typography,
  Button,
} from "@material-tailwind/react";
import { useFormik } from "formik";
import * as Yup from "yup";
import { useDispatch, useSelector } from "react-redux";
import { getUserDetails, registerUser } from "../../../redux/actions/userActions";
import { resetRegister } from "../../../redux/slices/userSlice";
import { Link, useNavigate } from "react-router-dom";
import { ArrowLongLeftIcon } from "@heroicons/react/24/outline";
import { useBreadcrumb } from "../../../Components/Breadcrumb/BreadcrumbContext";
const CreateAdmin = () => {
  const { setBreadcrumb } = useBreadcrumb();
  const navigation = useNavigate();
  const dispatch = useDispatch();
  const { isRegistered, userDetails } = useSelector((state) => state.users);
  const phoneRegExp = /^(\+?\d{1,4}[\s-])?(?!0+\s+,?$)\d{10,14}$/;
  const validationSchema = Yup.object({
    employeeID: Yup.string()
      .matches(/^\d+$/, "Employee ID must be a number") // Ensures only digits are allowed
      .required("Employee ID is required"),
    firstName: Yup.string().required("First Name is required"),

    lastName: Yup.string().required("Last Name is required"),
    email: Yup.string().email("Invalid email").required("Email is required"),
    phoneNumber: Yup.string()
      .matches(phoneRegExp, "Phone number is not valid")
      .required("Phone Number is required"),
    role: Yup.string().required("Role is required"),
  });

  const formik = useFormik({
    initialValues: {
      employeeID: "",
      firstName: "",
      middleName: "",
      lastName: "",
      email: "",
      confirmEmail: "",
      phoneNumber: "",
      role: "",
    },
    validationSchema,
    onSubmit: (values) => {
      console.log("Form submitted", values);
      dispatch(registerUser(values));

    },
  });
  useEffect(() => {
    if (isRegistered) {
      console.log('User registered successfully');
      dispatch(resetRegister());
      navigation('/dashboard/account');
    }
  }, [dispatch, isRegistered, navigation])
  useEffect(() => {
    dispatch(getUserDetails())
  }, [dispatch]);
  useEffect(() => {
    setBreadcrumb([
      { name: "Dashboard", path: "/dashboard" },
      { name: "Account", path: "/dashboard/account" },
      { name: "Create Employee Account" }
    ])
  }, [])
  return (
    <section className="w-full p-4">
      <div>
        <Link to="/dashboard/account">
          <div className="mb-4 h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
            <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
          </div>
        </Link>
        <Typography variant="h5" color="blue-gray">
          Create Employee Account
        </Typography>
        <Typography
          variant="small"
          className="text-gray-600 font-normal mt-1"
        >
          Create a new employee account and assign a role to them.
        </Typography>
        <div className="flex flex-col shadow-lg p-4 w-full mt-8">
          <form onSubmit={formik.handleSubmit} className="flex flex-col mt-8">
            <div className="mb-6 flex flex-col items-end gap-4 md:flex-row">
              <div className="w-full">
                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                  Employee ID
                </Typography>
                <Input
                  name="employeeID"
                  size="lg"
                  placeholder="123456"
                  className="w-full placeholder:opacity-100 focus:border-t-primary border-t-blue-gray-200"
                  onChange={formik.handleChange}
                  onBlur={formik.handleBlur}
                  value={formik.values.employeeID}
                />
                {formik.touched.employeeID && formik.errors.employeeID && (
                  <div className="text-red-500 text-sm">{formik.errors.employeeID}</div>
                )}
              </div>
              <div className="w-full">
                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                  Phone Number
                </Typography>
                <Input
                  name="phoneNumber"
                  size="lg"
                  placeholder="+123 0123 456 789"
                  className="w-full placeholder:opacity-100 focus:border-t-primary border-t-blue-gray-200"
                  onChange={formik.handleChange}
                  onBlur={formik.handleBlur}
                  value={formik.values.phoneNumber}
                />
                {formik.touched.phoneNumber && formik.errors.phoneNumber && (
                  <div className="text-red-500 text-sm">{formik.errors.phoneNumber}</div>
                )}
              </div>
            </div>

            <div className="mb-6 flex flex-col justify-center items-center gap-4 md:flex-row">
              <div className="w-full">
                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                  First Name
                </Typography>
                <Input
                  name="firstName"
                  size="lg"
                  placeholder="Emma"
                  className="w-full placeholder:opacity-100 focus:border-t-primary border-t-blue-gray-200"
                  onChange={formik.handleChange}
                  onBlur={formik.handleBlur}
                  value={formik.values.firstName}
                />
                {formik.touched.firstName && formik.errors.firstName && (
                  <div className="text-red-500 text-sm">{formik.errors.firstName}</div>
                )}
              </div>

              <div className="w-full">
                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                  Last Name
                </Typography>
                <Input
                  name="lastName"
                  size="lg"
                  placeholder="Roberts"
                  className="w-full placeholder:opacity-100 focus:border-t-primary border-t-blue-gray-200"
                  onChange={formik.handleChange}
                  onBlur={formik.handleBlur}
                  value={formik.values.lastName}
                />
                {formik.touched.lastName && formik.errors.lastName && (
                  <div className="text-red-500 text-sm">{formik.errors.lastName}</div>
                )}
              </div>
              <div className="w-full">
                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                  Middle Name
                </Typography>
                <Input
                  name="middleName"
                  size="lg"
                  placeholder="L."
                  className="w-full placeholder:opacity-100 focus:border-t-primary border-t-blue-gray-200"
                  onChange={formik.handleChange}
                  onBlur={formik.handleBlur}
                  value={formik.values.middleName}
                />
                {formik.touched.firstName && formik.errors.firstName && formik.errors.lastName && formik.touched.lastName && (
                  <div className="text-red-500 text-sm h-5"></div>
                )}
              </div>
            </div>

            <div className="mb-6 flex flex-col items-end gap-4 md:flex-row">
              <div className="w-full">
                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                  Email
                </Typography>
                <Input
                  name="email"
                  type="email"
                  size="lg"
                  placeholder="emma@mail.com"
                  className="w-full placeholder:opacity-100 focus:border-t-primary border-t-blue-gray-200"
                  onChange={formik.handleChange}
                  onBlur={formik.handleBlur}
                  value={formik.values.email}
                />
                {formik.touched.email && formik.errors.email && (
                  <div className="text-red-500 text-sm">{formik.errors.email}</div>
                )}
              </div>
              <div className="w-full">
                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                  Role
                </Typography>
                <select
                  name="role"
                  className="w-full border border-blue-gray-200 rounded-lg focus:border-primary"
                  onChange={formik.handleChange}
                  onBlur={formik.handleBlur}
                  value={formik.values.role}
                >
                  <option value="" label="Select Role" />
                  {userDetails?.role === "SuperAdmin" && <option value="Admin" label="Admin" />}
                  <option value="Staff" label="Staff" />
                </select>
                {formik.touched.role && formik.errors.role && (
                  <div className="text-red-500 text-sm">{formik.errors.role}</div>
                )}
              </div>
            </div>

            <Button type="submit" className="mt-6 bg-secondary w-max">
              Add new
            </Button>
          </form>
        </div>
      </div>
    </section>
  );
}

export default CreateAdmin;