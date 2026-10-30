exports.calculateAge = (birthday) => {
  const birthDate = new Date(birthday);
  const today = new Date();

  // Calculate total difference in milliseconds
  const diffTime = today - birthDate;
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  const diffWeeks = Math.floor(diffDays / 7);

  let years = today.getFullYear() - birthDate.getFullYear();
  let months = today.getMonth() - birthDate.getMonth();

  if (today.getDate() < birthDate.getDate()) {
    months--;
  }

  if (months < 0) {
    years--;
    months += 12;
  }

  if (years >= 1) {
    return { age: years, unit: 'years' };
  } else if (months >= 1) {
    return { age: months, unit: 'months' };
  } else if (diffDays >= 7) {
    return { age: diffWeeks, unit: 'weeks' };
  } else {
    return { age: diffDays, unit: 'days' };
  }
};


