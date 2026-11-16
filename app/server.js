const express= require('express');
const app= express();
const path= require("path")
const port= process.env.PORT;
const appName=process.env.APP_NAME
app.use("/images",express.static(path.join(__dirname + "/images")));
app.get("/",(req,res)=>{
    console.log(`hello from ${appName}`)
    res.sendFile(path
        .join(__dirname+ "/index.html"))

})
app.listen(port,()=>{
    console.log(`app is running on port ${port}`)
})