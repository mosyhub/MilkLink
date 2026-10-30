import { useEffect, useRef } from 'react';
import { useDispatch } from 'react-redux';
import { logoutUser } from './redux/actions/userActions'; // your thunk
import { useLocation } from 'react-router-dom';

const INACTIVITY_LIMIT = 60 * 60 * 1000; // 10 minutes

export default function InactivityHandler() {
  const dispatch = useDispatch();
  const timerRef = useRef(null);
  const location = useLocation();
  const pathName = location.pathname
  const resetTimer = () => {
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => {
      dispatch(logoutUser('inactivity'));
    }, INACTIVITY_LIMIT);
  };

  useEffect(() => {
    const events = ['mousemove', 'keydown', 'click', 'scroll'];


    console.log(pathName)
    if (pathName !== "/login" && pathName !== "/employee/login") {
      events.forEach(event => window.addEventListener(event, resetTimer));
      resetTimer(); // Start timer on mount
    }


    return () => {
      events.forEach(event => window.removeEventListener(event, resetTimer));
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [pathName]);

  return null; // This is a logic-only component
}
