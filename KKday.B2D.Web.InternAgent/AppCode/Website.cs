
namespace KKday.B2D.Web.InternAgent.AppCode
{
    public sealed class Website
    {
        public static readonly Website Instance = new Website();

        // Database Connection
        public string SqlConnectionString { get; private set; }

        public string KKdayApiUrl { get; private set; }
        public string KKdayApiAuthorizeToken { get; private set; }

        public string Currency  { get; private set; }
        public string Marketing  { get; private set; }
        public string GoogleMapsApiKey { get; private set; }

        // SSL validation control - ONLY for Development environment with self-signed certs
        public bool DisableSSLValidation { get; private set; }
        public bool IsDevelopment { get; private set; }

        private Website()
        {
            //
            // TODO: Add constructor logic here
            //
        }

        public void Init(IConfiguration config, bool isDevelopment = false)
        {
            this.KKdayApiUrl = config["KKdayApi:Url"];
            this.KKdayApiAuthorizeToken = config["KKdayApi:AuthorToken"];
            this.Currency = config["Currency"];
            this.Marketing = config["Marketing"];
            this.GoogleMapsApiKey = config["GoogleMapsApiKey"];
            this.IsDevelopment = isDevelopment;

            // Read SSL validation setting (default to false = validate certificates)
            var disableSSL = config["DisableSSLValidation"];
            this.DisableSSLValidation = !string.IsNullOrEmpty(disableSSL) &&
                                       bool.Parse(disableSSL);
        }

        /// <summary>
        /// Returns true if SSL validation should be disabled
        /// ONLY when both: IsDevelopment=true AND DisableSSLValidation=true
        /// </summary>
        public bool ShouldDisableSSLValidation()
        {
            return IsDevelopment && DisableSSLValidation;
        }

    }
}
