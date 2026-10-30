// BreadcrumbContext.js
import { createContext, useContext, useState, useMemo } from "react";
import PropTypes from "prop-types";
const BreadcrumbContext = createContext();

export const BreadcrumbProvider = ({ children }) => {
  const [breadcrumb, setBreadcrumb] = useState([
    { name: "Dashboard", path: "/dashboard" },
  ]);
  const value = useMemo(() => ({
    breadcrumb,
    setBreadcrumb,
  }), [breadcrumb, setBreadcrumb]);
  return (
    <BreadcrumbContext.Provider value={value}>
      {children}
    </BreadcrumbContext.Provider>
  );
};
BreadcrumbProvider.propTypes = {
  children: PropTypes.node.isRequired
}
export const useBreadcrumb = () => useContext(BreadcrumbContext);
