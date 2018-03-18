window.setInterval(updateProg,5000);

async function updateProg(){
    var prog = await fetchProg()
    for (i=0 ; i<=4; i++){
        document.getElementById("p"+i).innerHTML = prog.prog[i];
        console.log("Program fetched");
    }
}

async function fetchProg(){
  const response  =  await fetch('prog.json');
  return response.json();
}
