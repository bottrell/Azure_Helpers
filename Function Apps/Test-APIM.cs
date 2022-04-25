using System.Net.Http;
using Newtonsoft.Json;
using System;

namespace APICallDemo 
{
    public class Program
    {

        //creating an instance of HttpClient to handle requests and responses
        private static HttpClient client = new HttpClient();
        static void Main(string[] args)
        {
            CallLoggingAPI();
        }

        static void CallLoggingAPI()
        {   
            string baseurl = "{Your API URI here}";
            //body of the request, including the parameters that need to be sent to the API
            var body = new Dictionary<string, string>
            {
                {"FuncName", "APICallDemo"},
                {"LogType", "Warning"},
                {"CorrelationId", "383ca8bd-9d22-451d-8f21-7e0c6c40fc7e"},
                {"Message", "The API has been called successfully"},
                {"Custom_JSON_Details", @"{""Test"":""Yes""}" }
            };
            //adding headers
            client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", "{Your subscription Key here}");
            //serialize our dictionary into a json object
            string request = JsonConvert.SerializeObject(body);
            //Send the POST operation to the API
            HttpResponseMessage response = client.PostAsync(baseurl, new StringContent(request, System.Text.Encoding.UTF8, "application/json")).Result; 
            //send status code to console
            Console.WriteLine(response);
        }  
    }
}
