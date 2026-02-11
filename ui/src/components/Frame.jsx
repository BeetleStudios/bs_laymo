import { useEffect, useState } from 'react';
import './Frame.css';

export default function Frame({ children, theme }) {
    const [time, setTime] = useState('00:00');

    useEffect(() => {
        const updateTime = () => {
            const date = new Date();
            setTime(`${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`);
        };
        
        updateTime();
        const interval = setInterval(updateTime, 1000);
        return () => clearInterval(interval);
    }, []);

    return (
        <div className='phone-frame' data-theme={theme}>
            <div className='phone-notch'></div>
            <div className='phone-time' data-theme={theme}>{time}</div>
            <div className='phone-indicator'></div>
            <div className='phone-content'>{children}</div>
        </div>
    );
}
