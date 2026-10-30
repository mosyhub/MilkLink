// hooks/useCountUp.js
import { useEffect, useState } from 'react';

export function useCountUp(target, loading, duration = 1000, stepTime = 20) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (loading || target === null || target === undefined) {
      setCount(0);
      return;
    }

    let current = 0;
    const increment = Math.ceil(target / (duration / stepTime));

    const timer = setInterval(() => {
      current += increment;
      if (current >= target) {
        current = target;
        clearInterval(timer);
      }
      setCount(current);
    }, stepTime);

    return () => clearInterval(timer);
  }, [target, loading, duration, stepTime]);

  return count;
}
