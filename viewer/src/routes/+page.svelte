<script>
    import NetworkGraph from "./NetworkGraph.svelte";
    import { data } from "../../../data/network_graph.js"
 
/*
    // Example data for the network graph
  const nodes = [
    { id: 1, label: 'Node 1' },
    { id: 2, label: 'Node 2' },
    { id: 3, label: 'Node 3' },
    { id: 4, label: 'Node 4' },
    { id: 5, label: 'Node 5' },
  ];
  
  const edges = [
    { from: 1, to: 2 },
    { from: 1, to: 3 },
    { from: 2, to: 4 },
    { from: 2, to: 5 },
  ];
  */
</script>

<h1>LBS Network Graph</h1>

<NetworkGraph {data} />
